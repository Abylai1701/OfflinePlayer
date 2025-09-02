import Foundation
import SwiftData
import Kingfisher

@MainActor
final class MainViewModel: ObservableObject {
    
    // MARK: Router
    private weak var router: Router?
    
    private var manager: LocalPlaylistsManager?
    
    // Шаринг
    @Published var isShareSheetPresented = false
    @Published var shareItems: [Any] = []
    
    var trackURLProvider: ((MyTrack) -> URL?)?
    
    func attach(router: Router) {
        self.router = router
    }
    func pushToTrendingNow() {
        router?.push(.trendingNow(items: trendItems))
    }
    
    @MainActor
    func openPlaylist(_ p: MyPlaylist) async {
        isLoading = true
        errorMessage = nil
        do {
            let tracks = try await api.playlistTracks(id: p.id, limit: 200)
            prefetchTrackCovers(tracks.compactMap(\.artworkURL))
            router?.push(.playlistDetails(playlist: p, items: tracks))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: Audius
    private let host = AudiusHostProvider()
    private lazy var api = AudiusAPI(host: host, appName: "OfflineOlen", logLevel: .info)
    
    // MARK: UI State
    @Published var heroPlaylists: [MyPlaylist] = []
    @Published var trendItems: [MyTrack] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionTrack: MyTrack? = nil
    @Published var isActionSheetPresented = false
    
    @Published var playlistCovers: [String: URL] = [:]
    @Published var trackCovers: [String: URL] = [:]
    
    private var playlistPrefetcher: ImagePrefetcher?
    private var trackPrefetcher: ImagePrefetcher?
    
    // MARK: Bootstrap / Loading
    private(set) var currentCategory: HomeCategory = .popular
    
    func bootstrap(initial category: HomeCategory = .popular) async {
        await setCategory(category)
    }
    
    func coverURL(for p: MyPlaylist) -> URL? {
        playlistCovers[p.id] ?? p.artworkURL
    }
    func coverURL(for t: MyTrack) -> URL? {
        trackCovers[t.id] ?? t.artworkURL
    }
    
    func bindIfNeeded(context: ModelContext) {
        guard manager == nil else { return }
        manager = LocalPlaylistsManager(context: context)
        manager?.ensureFavoritesExists()
    }
    
    func setCategory(_ category: HomeCategory) async {
        
        guard category != .favorites else {
            return
        }
        
        isLoading = true
        
        if let feed = HomeCacheService.shared.feed(for: category) {
            heroPlaylists  = feed.playlists
            trendItems = feed.tracks
            playlistCovers = feed.playlistCovers
            trackCovers = feed.trackCovers
        } else {
            // если кэш ещё не готов (первая загрузка)
            await HomeCacheService.shared.refreshAll()
            if let feed = HomeCacheService.shared.feed(for: category) {
                heroPlaylists  = feed.playlists
                trendItems = feed.tracks
                playlistCovers = feed.playlistCovers
                trackCovers = feed.trackCovers
            }
        }
        isLoading = false
    }
    private func apply(_ feed: HomeFeed) {
        self.heroPlaylists  = feed.playlists
        self.trendItems = feed.tracks
        self.playlistCovers = feed.playlistCovers
        self.trackCovers = feed.trackCovers
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
            
            let time = category.timeWindow
            let genre = category.genre
            
            // 1) Параллельно грузим плейлисты и треки
            async let p: [MyPlaylist] = api.trendingPlaylists(time: time, limit: 20)
            async let t: [MyTrack] = api.trendingTracks(time: time, genre: genre, limit: 20)
            let (playlists, tracks) = try await (p, t)
            
            // 2) Отрисуем в UI
            self.heroPlaylists = playlists
            self.trendItems = tracks
            
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
    func closeActions() {
        isActionSheetPresented = false
    }
    
    func like() {}
    func addToPlaylist() {}
    func playNext() {}
    
    func download() {
        //        guard let t = actionTrack, let url = try? api.streamURL(for: t.id) else { return }
        // DownloadService.shared.download(trackId: t.id, from: url)
    }
    
    func share() {}
    func goToAlbum() {}
    func remove() {}
    
    
    func addCurrentTrackToFavorites() {
        guard let m = manager, let t = actionTrack else { return }
        let fav = m.ensureFavoritesExists()
        
        // не создаём дубликаты (по audiusId)
        if fav.items.contains(where: { $0.track?.audiusId == t.id }) { return }
        
        _ = m.addAudiusTrack(t, to: fav)
        // можно показать тост по желанию
    }
    
    // MARK: - Share (track)
    func shareCurrentTrack() {
        guard let t = actionTrack else { return }
        let text = "Track: \(t.title)\nArtist: \(t.artist.isEmpty ? "—" : t.artist)"
        
        var items: [Any] = [text]
        if let url = trackURLProvider?(t) {
            items.append(url)
        } else if let art = t.artworkURL {
            items.append(art) // фолбэк — обложка
        }
        
        shareItems = items
        isShareSheetPresented = true
    }
    // MARK: - Search Logic
    
    // MARK: - Search state
    @Published var searchText: String = ""
    @Published var searchScope: SearchScope = .top
    
    @Published var foundTracks: [MyTrack] = []
    @Published var foundPlaylists: [MyPlaylist] = []
    @Published var foundAlbums: [MyPlaylist] = []
    @Published var foundArtists: [String] = []
    
    private var searchWorkItem: DispatchWorkItem?
    
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func onSearchTextChanged() {
        searchWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                await self?.performLocalSearch()
            }
        }
        searchWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
    }
    
    private func norm(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    private func matches(_ text: String, q: String) -> Bool {
        norm(text).contains(norm(q))
    }
    
    /// Поиск ТОЛЬКО по LocalLibrary
    func performLocalSearch() async {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            foundTracks = []; foundPlaylists = []; foundAlbums = []; foundArtists = []
            return
        }
        
        let lib = LocalLibrary.shared
        
        let t = lib.tracks.filter { t in
            matches(t.title, q: q) || matches(t.artist, q: q)
        }
        
        let pls = lib.regularPlaylists.filter { p in
            matches(p.title, q: q) || matches(p.user?.name ?? p.user?.handle ?? "", q: q)
        }
        let als = lib.albums.filter { p in
            matches(p.title, q: q) || matches(p.user?.name ?? p.user?.handle ?? "", q: q)
        }
        
        let artistsSet = Set(t.compactMap { $0.artist.isEmpty ? nil : $0.artist })
        let artists = Array(artistsSet).sorted { $0 < $1 }
        
        self.foundTracks = t
        
        var seen = Set<String>()
        foundTracks = foundTracks.filter { seen.insert($0.id).inserted }
        
        self.foundPlaylists = pls
        
        var seenP = Set<String>()
        foundPlaylists = foundPlaylists.filter { seenP.insert($0.id).inserted }
        
        self.foundAlbums = als
        
        var seenA = Set<String>()
        foundAlbums = foundAlbums.filter { seenA.insert($0.id).inserted }
        
        self.foundArtists = artists
    }
}

// MARK: - Маппинг категорий → API
extension HomeCategory {
    var timeWindow: TimeWindow {
        switch self {
        case .popular:
            return .month
        case .new:
            return .week
        case .trend:
            return .week
        case .favorites:
            return .month
        case .relax:
            return .month
        case .sport:
            return .month
        }
    }
    var genre: AudiusGenre? {
        switch self {
        case .relax:
            return .jazz
        case .sport:
            return .hipHop
        default:
            return nil
        }
    }
}


extension MainViewModel {
    
    @MainActor
    func play(_ t: MyTrack) {
        Task {
            await PlaybackService.shared.play(t)
        }
    }
    
    @MainActor
    func playAllTrending(startAt idx: Int = 0) {
        Task {
            await PlaybackService.shared.playQueue(trendItems, startAt: idx)
        }
    }
}
