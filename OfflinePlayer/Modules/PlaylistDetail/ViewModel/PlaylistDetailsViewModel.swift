import SwiftUI

@MainActor
final class PlaylistDetailsViewModel: ObservableObject {
    private weak var router: Router?
    
    @Published var tracks: [MyTrack] = []
    @Published var playlist: MyPlaylist
    @Published var isActionSheetPresented = false
    @Published var isShowMenuTapped = false
    @Published var actionTrack: MyTrack? = nil
    
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
    func share() {}
    func goToAlbum() {}
    func remove() {}
}
