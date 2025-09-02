import SwiftUI
import SwiftData

@MainActor
final class PlaylistDetailsViewModel: ObservableObject {
    private weak var router: Router?
    
    @Published var tracks: [MyTrack] = []
    @Published var playlist: MyPlaylist
    @Published var isActionSheetPresented = false
    @Published var isShowMenuTapped = false
    @Published var actionTrack: MyTrack? = nil
    
    @Published var isShareSheetPresented = false
    @Published var shareItems: [Any] = []
    
    private var manager: LocalPlaylistsManager?
    
    // ⬇️ провайдеры внешних ссылок (если есть permalink'и)
    var playlistURLProvider: ((MyPlaylist) -> URL?)?
    var trackURLProvider: ((MyTrack) -> URL?)?
    
    private let api = AudiusAPI(host: AudiusHostProvider(), appName: "OfflineOlen", logLevel: .info)
    
    init(tracks: [MyTrack], playlist: MyPlaylist) {
        self.tracks = tracks
        self.playlist = playlist
    }
    
    func attach(router: Router) {
        self.router = router
    }
    
    @MainActor func back() {
        router?.pop()
    }
    func refresh() async {
        do {
            let full = try await api.playlistTracks(id: playlist.id, limit: 200)
            await MainActor.run { self.tracks = full }
        } catch {}
    }
    
    
    //MARK: - Тап по “три точки”
    func openActions(for track: MyTrack) {
        actionTrack = track
        isActionSheetPresented = true
    }
    
    func openMenu() {
        isShowMenuTapped = true
    }
    
    func closeMenu() {
        isShowMenuTapped = false
    }
    
    func closeActions() {
        isActionSheetPresented = false
    }
    
    // Примеры экшенов (заглушки)
    func like() {}
    func addToPlaylist() {}
    func playNext() {}
    func download() {}
    func goToAlbum() {}
    func remove() {}
    
    // MARK: - Share: ВЕСЬ ПЛЕЙЛИСТ
    func sharePlaylist() {
        let header = "Playlist: \(playlist.title)"
        let lines = tracks.enumerated().map { idx, t in
            "\(idx + 1). \(t.title) — \(t.artist.isEmpty ? "—" : t.artist)"
        }
        let text = ([header, ""] + lines).joined(separator: "\n")
        
        var items: [Any] = [text]
        if let url = playlistURLProvider?(playlist) {
            items.append(url)
        }
        
        shareItems = items
        isShareSheetPresented = true
    }
    
    // MARK: - Share: ОДИН ТРЕК
    func shareTrack(_ track: MyTrack) {
        let text = "Track: \(track.title)\nArtist: \(track.artist.isEmpty ? "—" : track.artist)"
        var items: [Any] = [text]
        if let url = trackURLProvider?(track) {
            items.append(url)
        }
        
        shareItems = items
        isShareSheetPresented = true
    }
    
    /// Удобно вызывать из action sheet по текущему выбранному треку
    func shareCurrentTrack() {
        guard let t = actionTrack else { return }
        shareTrack(t)
    }
    
    // для совместимости, если где-то уже зовёшь share()
    func share() {
        sharePlaylist()
    }
    
    // вызывать из View один раз
    func bindIfNeeded(context: ModelContext) {
        guard manager == nil else { return }
        manager = LocalPlaylistsManager(context: context)
        manager?.ensureFavoritesExists()
    }
    
    // MARK: - Favorites
    func addCurrentTrackToFavorites() {
        guard let m = manager, let t = actionTrack else { return }
        let fav = m.ensureFavoritesExists()
        // дубли не добавляем
        if fav.items.contains(where: { $0.track?.audiusId == t.id }) { return }
        _ = m.addAudiusTrack(t, to: fav)   // создаст LocalTrack + PlaylistItem, сохранит
    }
    
    @MainActor
    func playQueue(_ tracks: [MyTrack], startAt index: Int = 0) async {
        do {
            let urls = try await withThrowingTaskGroup(of: (Int, URL).self) { group -> [URL] in
                for (i, t) in tracks.enumerated() {
                    group.addTask {
                        let u = try await self.api.streamURL(for: t.id)
                        return (i, u)
                    }
                }
                var result = Array(repeating: URL(string: "about:blank")!, count: tracks.count)
                for try await (i, u) in group { result[i] = u }
                return result
            }
            let entries = zip(tracks.indices, tracks).map { i, t in
                PlayerQueueEntry(
                    id: t.id,
                    url: urls[i],
                    meta: .init(title: t.title, artist: t.artist, artworkURL: t.artworkURL)
                )
            }
            PlayerCenter.shared.setQueue(entries, startAt: index, autoplay: true)
        } catch {
            print("playQueue error:", error.localizedDescription)
        }
    }
    
    @MainActor
    func play(startAt idx: Int = 0) {
        Task { await PlaybackService.shared.playQueue(tracks, startAt: idx) }
    }
    
}
