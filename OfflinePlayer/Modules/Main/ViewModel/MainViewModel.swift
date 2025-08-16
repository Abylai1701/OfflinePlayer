import Foundation

final class MainViewModel: ObservableObject {
    
    private weak var router: Router?
    @Published var trendItems: [Track] = []
    @Published var isActionSheetPresented = false
    @Published var actionTrack: Track? = nil
    
    /// Позволяет инжектить Router из View (через .environmentObject)
    func attach(router: Router) {
        self.router = router
    }
    
    @MainActor func pushToTrendingNow() {
        router?.push(.trendingNow)
    }
    
    // Тап по “три точки”
    func openActions(for track: Track) {
        actionTrack = track
        isActionSheetPresented = true
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
