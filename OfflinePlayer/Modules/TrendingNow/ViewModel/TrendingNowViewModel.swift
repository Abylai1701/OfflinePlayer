import Foundation
import SwiftData

@MainActor
final class TrendingNowViewModel: ObservableObject {
    
    private weak var router: Router?

    @Published var search = ""
    @Published var items: [MyTrack]
    @Published var actionTrack: MyTrack? = nil
    @Published var isActionSheetPresented = false

    @Published var isShareSheetPresented = false
    @Published var shareItems: [Any] = []

    private var manager: LocalPlaylistsManager?
    var trackURLProvider: ((MyTrack) -> URL?)?
    
    init(items: [MyTrack]) {
        self.items = items
    }
    
    func attach(router: Router) {
        self.router = router
    }

    @MainActor func back() {
        router?.pop()
    }

    // Тап по “три точки”
    @MainActor func openActions(for track: MyTrack) {
        actionTrack = track
        isActionSheetPresented = true
    }
    
    @MainActor func closeActions() {
        isActionSheetPresented = false
    }

    // Примеры экшенов (заглушки)
    func like() {}
    func addToPlaylist() {}
    func playNext() {}
    func download() {}
    func share() {}
    func goToAlbum() {}
    func remove() {}
    
    func bindIfNeeded(context: ModelContext) {
        guard manager == nil else { return }
        manager = LocalPlaylistsManager(context: context)
        manager?.ensureFavoritesExists()
    }
    
    // MARK: - Favorites
    func addCurrentTrackToFavorites() {
        guard let m = manager, let t = actionTrack else { return }
        let fav = m.ensureFavoritesExists()
        // не добавляем дубликаты по audiusId
        if fav.items.contains(where: { $0.track?.audiusId == t.id }) { return }
        _ = m.addAudiusTrack(t, to: fav)
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

}
