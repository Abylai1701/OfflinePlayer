import SwiftUI
import SwiftData

@MainActor
final class PlaylistViewModel: ObservableObject {
    
    private weak var router: Router?
    private var manager: LocalPlaylistsManager?

    @Published var playlists: [LocalPlaylist] = []

    func attach(router: Router) {
        self.router = router
    }

    func bindIfNeeded(context: ModelContext) {
        guard manager == nil else { return }
        manager = LocalPlaylistsManager(context: context)
        manager?.ensureFavoritesExists()
        refresh()
    }

    func refresh() {
        playlists = manager?.fetchPlaylists() ?? []
    }

    func createPlaylist(named name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        manager?.createPlaylist(title: name)
        refresh()
    }

    func delete(at offsets: IndexSet) {
        guard let m = manager else { return }
        for i in offsets {
            let p = playlists[i]
            m.deletePlaylist(p)
        }
        refresh()
    }

    // навигация — когда будет готов экран деталей для локальных плейлистов
    @MainActor func pushToDetail(_ playlist: LocalPlaylist) {
        router?.push(.localPlaylist(playlist: playlist)) // пример
    }

    @MainActor func back() {
        router?.pop()
    }
}
