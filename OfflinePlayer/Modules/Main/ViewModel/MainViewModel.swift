import Foundation
import Kingfisher

@MainActor
final class MainViewModel: ObservableObject {

    // MARK: Router
    private weak var router: Router?
    
    func attach(router: Router) {
        self.router = router
    }
    func pushToTrendingNow() {
        router?.push(.trendingNow(items: trendItems))
    }
    func pushToDetail() {
        router?.push(.playlistDetails)
    }

    // MARK: Audius
    private let host = AudiusHostProvider()
    private lazy var api = AudiusAPI(host: host, appName: "OfflineOlen")

    // MARK: UI State
    @Published var heroPlaylists: [MyPlaylist] = []
    @Published var trendItems: [MyTrack] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionTrack: MyTrack? = nil
    @Published var isActionSheetPresented = false

    // Итоговые URL’ы обложек (включая фолбэки)
    @Published var playlistCovers: [String: URL] = [:]
    @Published var trackCovers: [String: URL] = [:]

    // Kingfisher префетчеры нужно удерживать
    private var playlistPrefetcher: ImagePrefetcher?
    private var trackPrefetcher: ImagePrefetcher?

    // MARK: Bootstrap / Loading
    private(set) var currentCategory: HomeCategory = .popular

    func bootstrap(initial category: HomeCategory = .popular) async {
        await setCategory(category)
    }

    // Удобные геттеры в UI
    func coverURL(for p: MyPlaylist) -> URL? {
        playlistCovers[p.id] ?? p.artworkURL
    }
    func coverURL(for t: MyTrack) -> URL? {
        trackCovers[t.id] ?? t.artworkURL
    }

    func setCategory(_ category: HomeCategory) async {
        currentCategory = category
        await loadHome(category: category)
    }

    private func loadHome(category: HomeCategory) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await host.ensureHost()

            if category == .favorites {
                heroPlaylists = []
                trendItems    = []
                playlistCovers = [:]
                trackCovers    = [:]
                // Остановим префетчеры
                playlistPrefetcher?.stop(); playlistPrefetcher = nil
                trackPrefetcher?.stop();    trackPrefetcher    = nil
                return
            }

            let time  = category.timeWindow
            let genre = category.genre

            // 1) Параллельно грузим плейлисты и треки
            async let p: [MyPlaylist] = api.trendingPlaylists(time: time, limit: 20)
            async let t: [MyTrack]    = api.trendingTracks(time: time, genre: genre, limit: 20)
            let (playlists, tracks) = try await (p, t)

            // 2) Отрисуем в UI
            self.heroPlaylists = playlists
            self.trendItems    = tracks

            // 3) Достраиваем фолбэки для плейлистов (artwork -> user avatar -> первые треки)
            await buildPlaylistCovers(for: playlists)

            // (Опционально: фолбэки для треков; пока берём только их собственные artwork)
            self.trackCovers = Dictionary(uniqueKeysWithValues: tracks.compactMap { t in
                t.artworkURL.map { (t.id, $0) }
            })

            // 4) Префетчим уже итоговые URL’ы
            let plURLs = heroPlaylists.compactMap { coverURL(for: $0) }
            prefetchPlaylistCovers(plURLs)

            let trURLs = trendItems.compactMap { coverURL(for: $0) }
            prefetchTrackCovers(trURLs)

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: Covers

    private func buildPlaylistCovers(for lists: [MyPlaylist]) async {
        var dict: [String: URL] = [:]

        // Локальная не-actor-isolated функция: можно безопасно вызывать в фоновых тасках
        let bestUserPictureURL: (MyPlaylist.User?) -> URL? = { u in
            u?.profilePicture?._1000x1000 ?? u?.profilePicture?._480x480 ?? u?.profilePicture?._150x150
        }

        await withTaskGroup(of: (String, URL?).self) { group in
            for p in lists {
                group.addTask { [api] in
                    // 1) artwork плейлиста
                    if let u = p.artworkURL { return (p.id, u) }
                    // 2) аватар автора (если вдруг появится)
                    if let u = bestUserPictureURL(p.user) { return (p.id, u) }
                    // 3) возьмём обложку из первых 5 треков
                    if let tracks = try? await api.playlistTracks(id: p.id, limit: 5),
                       let u = tracks.compactMap(\.artworkURL).first {
                        return (p.id, u)
                    }
                    // 4) не нашли
                    return (p.id, nil)
                }
            }
            for await (id, url) in group {
                if let u = url { dict[id] = u }
            }
        }

        self.playlistCovers = dict
    }

    private func prefetchPlaylistCovers(_ urls: [URL]) {
        playlistPrefetcher?.stop()
        playlistPrefetcher = ImagePrefetcher(urls: urls, options: [
            .processor(DownsamplingImageProcessor(size: CGSize(width: 152.fitW, height: 152.fitW))),
            .cacheOriginalImage,
            .loadDiskFileSynchronously
        ])
        playlistPrefetcher?.start()
    }

    private func prefetchTrackCovers(_ urls: [URL]) {
        trackPrefetcher?.stop()
        trackPrefetcher = ImagePrefetcher(urls: urls, options: [
            .processor(DownsamplingImageProcessor(size: CGSize(width: 60.fitW, height: 60.fitW))),
            .cacheOriginalImage,
            .loadDiskFileSynchronously
        ])
        trackPrefetcher?.start()
    }

    // MARK: Actions (трёхточечное меню)
    func openActions(for track: MyTrack) {
        actionTrack = track
        isActionSheetPresented = true
    }
    func closeActions() { isActionSheetPresented = false }

    func like() {}
    func addToPlaylist() {}
    func playNext() {}

    func download() {
        guard let t = actionTrack, let url = try? api.streamURL(for: t.id) else { return }
        // DownloadService.shared.download(trackId: t.id, from: url)
    }

    func share() {}
    func goToAlbum() {}
    func remove() {}
}

// MARK: - Маппинг категорий → API
private extension HomeCategory {
    var timeWindow: TimeWindow {
        switch self {
        case .popular:   return .month
        case .new:       return .week
        case .trend:     return .week
        case .favorites: return .month
        case .relax:     return .month
        case .sport:     return .month
        }
    }
    var genre: AudiusGenre? {
        switch self {
        case .relax: return .electronic
        case .sport: return .hipHop
        default:     return nil
        }
    }
}
