import SwiftUI
import SwiftData
import Kingfisher

@MainActor
final class LibraryViewModel: ObservableObject {
    
    // MARK: - DI / Inputs
    private weak var router: Router?
    private(set) var context: ModelContext?
    private(set) var targetPlaylist: LocalPlaylist
    
    // MARK: - API
    private let host = AudiusHostProvider()
    private lazy var api = AudiusAPI(host: host, appName: "OfflineOlen", logLevel: .info)
    
    // MARK: - UI State
    @Published var query: String = ""
    @Published private(set) var results: [MyTrack] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // дебаунс
    private var pendingSearch: DispatchWorkItem?
    
    init(playlist: LocalPlaylist) {
        self.targetPlaylist = playlist
    }
    
    // MARK: - Wiring
    func attach(router: Router) {
        self.router = router
    }
    func bindIfNeeded(context: ModelContext?) {
        if self.context == nil {
            self.context = context
        }
    }
    func back() {
        router?.pop()
    }
    
    // MARK: - Search
    func onQueryChanged() {
        pendingSearch?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { await self?.performSearch() }
        }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }
    
    private func performSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            self.results = []
            self.errorMessage = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await host.ensureHost()
            let tracks = try await api.searchTracks(q, limit: 50, offset: 0)
            
            // Уберём дубли по id (на всякий случай)
            var seen = Set<String>()
            let unique = tracks.filter { seen.insert($0.id).inserted }
            self.results = unique
        } catch {
            self.results = []
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Add to local playlist (SwiftData)
    func addToPlaylist(_ t: MyTrack) {
        guard let ctx = context else { return }
        
        let pid = targetPlaylist.id
        let qid = t.id
        
        // Проверка на дубликаты: есть ли уже такой трек с таким audiusId в плейлисте
        var checkReq = FetchDescriptor<PlaylistItem>(
            predicate: #Predicate { item in
                item.playlist?.id == pid && item.track?.audiusId == qid
            },
            sortBy: []
        )
        checkReq.fetchLimit = 1
        
        if let existing = try? ctx.fetch(checkReq).first, existing != nil {
            return // уже добавлен
        }
        
        // Найти или создать LocalTrack
        let localTrack: LocalTrack
        let existingTrackReq = FetchDescriptor<LocalTrack>(
            predicate: #Predicate { $0.audiusId == qid },
            sortBy: []
        )
        if let match = try? ctx.fetch(existingTrackReq).first {
            localTrack = match
        } else {
            let newTrack = LocalTrack(
                source: .audius,
                title: t.title,
                artist: t.artist,
                duration: t.duration.map(Double.init),
                localFilename: nil,
                localBookmark: nil,
                audiusId: t.id,
                artworkURLString: t.artworkURL?.absoluteString,
                artworkThumb: nil
            )
            ctx.insert(newTrack)
            localTrack = newTrack
        }
        
        
        // Найти следующий индекс
        var lastReq = FetchDescriptor<PlaylistItem>(
            predicate: #Predicate { $0.playlist?.id == pid },
            sortBy: [SortDescriptor(\.sortIndex, order: .reverse)]
        )
        lastReq.fetchLimit = 1
        let last = try? ctx.fetch(lastReq).first
        let nextIndex = (last?.sortIndex ?? -1) + 1
        
        // Добавить PlaylistItem
        let newItem = PlaylistItem(
            sortIndex: nextIndex,
            playlist: targetPlaylist,
            track: localTrack
        )
        ctx.insert(newItem)
        
        do {
            try ctx.save()
        } catch {
            print("addToPlaylist save error:", error.localizedDescription)
        }
    }
    
}
