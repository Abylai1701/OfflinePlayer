import Foundation

final class TrendingNowViewModel: ObservableObject {
    private weak var router: Router?

    @Published var search = ""
    @Published var items: [Track] = []
    @Published var actionTrack: Track? = nil
    @Published var isActionSheetPresented = false

    func attach(router: Router) {
        self.router = router
    }

    @MainActor func back() {
        router?.pop()
    }

    // Тап по “три точки”
    @MainActor func openActions(for track: Track) {
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
}
