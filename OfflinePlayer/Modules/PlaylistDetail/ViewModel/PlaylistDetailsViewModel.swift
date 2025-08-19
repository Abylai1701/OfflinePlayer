import SwiftUI

final class PlaylistDetailsViewModel: ObservableObject {
    private weak var router: Router?
    
    @Published var tracks: [Track] = []
    @Published var isActionSheetPresented = false
    @Published var isShowMenuTapped = false
    @Published var actionTrack: Track? = nil
    
    func attach(router: Router) {
        self.router = router
    }
    
    @MainActor func back() {
        router?.pop()
    }
    
    @MainActor func pushToLibrary() {
        router?.push(.library)
    }
    
    //MARK: - Тап по “три точки”
    func openActions(for track: Track) {
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
    func share() {}
    func goToAlbum() {}
    func remove() {}
}
