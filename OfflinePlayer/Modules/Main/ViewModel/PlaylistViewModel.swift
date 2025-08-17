import SwiftUI

final class PlaylistViewModel: ObservableObject {
    private weak var router: Router?
    
    @Published var playlistItems: [Playlist] = []
    
    /// Позволяет инжектить Router из View (через .environmentObject)
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
