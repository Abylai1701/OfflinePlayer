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
    
    var trackURLProviderAsync: ((MyTrack) async throws -> URL)?
    
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
    func playNext(track: MyTrack) {
        Task {
            await PlaybackService.shared.enqueue(track)
        }
    }
    func download(_ track: MyTrack) {
        Task {
            do {

                let url = try await PlaybackService.shared.streamURL(for: track)

                let base = track.artist.isEmpty ? track.title : "\(track.artist) - \(track.title)"
                let saved = try await DownloadManager.shared.downloadTrack(
                    from: url,
                    suggestedName: base
                )
                print("✅ Saved to:", saved.path)
            } catch {
                print("Download error:", error.localizedDescription)
            }
        }
    }

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
    
    // MARK: - Search
    @Published var filtered: [MyTrack] = []
    private var searchWorkItem: DispatchWorkItem?
    
    private func norm(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    private func matches(_ text: String, q: String) -> Bool {
        norm(text).contains(norm(q))
    }
    
    func onSearchTextChanged() {
        searchWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let q = self.search.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = q.isEmpty
            ? self.items
            : self.items.filter { t in self.matches(t.title, q: q) || self.matches(t.artist, q: q) }
            DispatchQueue.main.async {
                self.filtered = result
            }
        }
        searchWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
    }
    
    
    
    
    
}
