import SwiftUI

final class PlaylistViewModel: ObservableObject {
    private weak var router: Router?
    
    @Published var playlistItems: [Playlist] = []
    
    func attach(router: Router) {
        self.router = router
    }
    
    @MainActor func pushToDetail() {
        router?.push(.playlistDetails)
    }
    
    @MainActor func back() {
        router?.pop()
    }
}
