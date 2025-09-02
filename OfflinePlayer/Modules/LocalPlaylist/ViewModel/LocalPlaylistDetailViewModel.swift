import Foundation
import SwiftUI
import SwiftData

@MainActor
final class LocalPlaylistDetailViewModel: ObservableObject {
    // Router
    private weak var router: Router?
    
    // SwiftData
    private var context: ModelContext?
    
    // Входные данные
    @Published var playlist: LocalPlaylist
    
    // UI state
    @Published var isActionSheetPresented = false
    @Published var isRenameSheetPresented = false
    @Published var isShowMenuTapped = false
    @Published var localActionTrack: LocalTrack? = nil   // <- для локального шита
    
    var isProtected: Bool { playlist.isProtected || playlist.title.caseInsensitiveCompare("Favorites") == .orderedSame }
    
    @Published var actionItem: PlaylistItem? = nil
    @Published var actionAudiusTrack: MyTrack? = nil
    
    // Данные для списка
    @Published private(set) var items: [PlaylistItem] = []
    @Published private(set) var rows: [Row] = []
    
    @Published var isShareSheetPresented = false
    @Published var shareItems: [Any] = []
    
    // Audius API при необходимости
    private lazy var api = AudiusAPI(host: AudiusHostProvider(), appName: "OfflineOlen", logLevel: .info)
    
    init(playlist: LocalPlaylist) {
        self.playlist = playlist
    }
    
    // Wiring
    func attach(router: Router) { self.router = router }
    
    func bindIfNeeded(context: ModelContext) {
        guard self.context == nil else {
            Task { await refresh() }
            return
        }
        self.context = context
        Task { await refresh() }
    }
    
    // Navigation
    func back() {
        router?.pop()
    }
    func pushToLibrary() {
        router?.push(.library(playlist: playlist))
    }
    
    // Menu / actions
    func openMenu() {
        isShowMenuTapped = true
    }
    func closeMenu() {
        isShowMenuTapped = false
    }
    
    func deletePlaylist() async {
        guard let ctx = context else { return }
        ctx.delete(playlist)
        try? ctx.save()
        back()
    }
    func openActions(for item: PlaylistItem) {
        actionItem = item
        localActionTrack = item.track
        
        actionAudiusTrack = mapToMyTrackIfAudius(item.track)
        isActionSheetPresented = true
    }
    
    func closeActions() {
        isActionSheetPresented = false
        actionItem = nil
        localActionTrack = nil
        actionAudiusTrack = nil
    }
    
    // Заглушки
    func like() {}
    func addToPlaylist() {}
    func playNext() {}
    func download() {}
    func share() {}
    func goToAlbum() {}
    
    func remove() {
        guard let ctx = context, let item = actionItem else { return }
        do {
            ctx.delete(item)
            try ctx.save()
            Task { await refresh() }
        } catch {
            print("Remove error:", error.localizedDescription)
        }
        closeActions()
    }
    
    // MARK: Fetch / Build
    
    func refresh() async {
        guard let ctx = context else { return }
        
        // ВАЖНО: захватываем значение во внешний let, а не self.playlist.id прямо в #Predicate
        let targetID: UUID = playlist.id
        
        do {
            let predicate = #Predicate<PlaylistItem> { item in
                item.playlist?.id == targetID
            }
            
            let req = FetchDescriptor<PlaylistItem>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
            )
            
            let fetched = try ctx.fetch(req)
            self.items = fetched
            self.rows = fetched.map { Row.from(item: $0) }
        } catch {
            print("refresh error:", error.localizedDescription)
        }
    }
    
    
    // MARK: Add / Import
    
    func importFromDevice() async {
        // показать документ-пикер / медиапикер → создать LocalTrack → PlaylistItem → save
    }
    
    /// Добавить локальные файлы из документ-пикера.
    /// ВАЖНО: скопировать в контейнер приложения, иначе доступ пропадёт.
    func importLocalFiles(urls: [URL]) {
        guard let ctx = context else { return }
        do {
            var maxIndex = (items.map(\.sortIndex).max() ?? -1)
            for src in urls {
                let dst = try copyIntoAppContainer(srcURL: src)
                
                let track = LocalTrack(
                    source: .localFile,
                    title: dst.deletingPathExtension().lastPathComponent,
                    artist: "",
                    duration: nil,
                    localFilename: dst.lastPathComponent,
                    localBookmark: nil,
                    audiusId: nil,
                    artworkURLString: nil,
                    artworkThumb: nil
                )
                let item = PlaylistItem(sortIndex: maxIndex + 1, playlist: playlist, track: track)
                maxIndex += 1
                
                ctx.insert(track)
                ctx.insert(item)
            }
            try ctx.save()
            Task {
                await refresh()
            }
        } catch {
            print("importLocalFiles error:", error.localizedDescription)
        }
    }
    
    /// Добавить треки из Audius.
    func addAudiusTracks(_ tracks: [MyTrack]) {
        guard let ctx = context else { return }
        do {
            var maxIndex = (items.map(\.sortIndex).max() ?? -1)
            for t in tracks {
                let lt = LocalTrack(
                    source: .audius,
                    title: t.title,
                    artist: t.artist,
                    duration: t.duration.map { Double($0) },
                    localFilename: nil,
                    localBookmark: nil,
                    audiusId: t.id,
                    artworkURLString: t.artworkURL?.absoluteString,
                    artworkThumb: nil
                )
                let item = PlaylistItem(sortIndex: maxIndex + 1, playlist: playlist, track: lt)
                maxIndex += 1
                
                ctx.insert(lt)
                ctx.insert(item)
            }
            try ctx.save()
            Task { await refresh() }
        } catch {
            print("addAudiusTracks error:", error.localizedDescription)
        }
    }
    
    // MARK: Helpers
    
    private func copyIntoAppContainer(srcURL: URL) throws -> URL {
        let fm = FileManager.default
        let lib = try fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = lib.appendingPathComponent("Audio", isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let ext = srcURL.pathExtension.isEmpty ? "dat" : srcURL.pathExtension
        let dst = folder.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        
        var needStop = false
        if srcURL.startAccessingSecurityScopedResource() { needStop = true }
        defer { if needStop { srcURL.stopAccessingSecurityScopedResource() } }
        
        try fm.copyItem(at: srcURL, to: dst)
        return dst
    }
    
    private func mapToMyTrackIfAudius(_ t: LocalTrack?) -> MyTrack? {
        guard let t, t.source == .audius, let id = t.audiusId else { return nil }
        return MyTrack(
            id: id,
            title: t.title,
            duration: t.duration.map { Int($0) },
            user: .init(handle: nil, name: t.artist.isEmpty ? nil : t.artist),
            artwork: nil
        )
    }
    
    func updateArtwork(with data: Data?) {
        playlist.artworkData = data
        playlist.updatedAt = Date()
        try? context?.save()
        // ничего дополнительно не нужно: @Published playlist обновится и вью перерисуется
    }
    
    func sharePlaylist() {
        // Собираем актуальные элементы из items по sortIndex
        let sorted = items.sorted { $0.sortIndex < $1.sortIndex }
        
        let header = "Playlist: \(playlist.title)"
        let lines: [String] = sorted.enumerated().map { idx, it in
            let t = it.track
            let title = (t?.title.isEmpty == false ? t!.title : "Unknown")
            let artist = (t?.artist.isEmpty == false ? t!.artist : "—")
            return "\(idx + 1). \(title) — \(artist)"
        }
        
        let body = ([header, ""] + lines).joined(separator: "\n")
        
        var itemsToShare: [Any] = [body]
        
        if let data = playlist.artworkData, let img = UIImage(data: data) {
            itemsToShare.append(img)
        }
        
        self.shareItems = itemsToShare
        self.isShareSheetPresented = true
    }
    
    func shareLocalTrack() {
        guard let t = localActionTrack else { return }
        
        let text = "Track: \(t.title)\nArtist: \(t.artist.isEmpty ? "—" : t.artist)"
        var items: [Any] = [text]
        
        // локальный thumbnail, если есть
        if let data = t.artworkThumb, let img = UIImage(data: data) {
            items.append(img)
        }
        
        // если трек из Audius и есть artwork URL — можно приложить ссылку
        if let s = t.artworkURLString, let url = URL(string: s) {
            items.append(url)
        }
        
        self.shareItems = items
        self.isShareSheetPresented = true
    }
    
    // MARK: - View snapshot
    struct Row: Identifiable, Hashable {
        let id: UUID
        let title: String
        let artist: String
        let artworkThumb: Data?
        let remoteArtworkURL: URL?
        
        static func from(item: PlaylistItem) -> Row {
            let t = item.track
            return Row(
                id: item.id,
                title: t?.title ?? "Unknown",
                artist: t?.artist ?? "",
                artworkThumb: t?.artworkThumb,
                remoteArtworkURL: (t?.artworkURLString).flatMap(URL.init(string:))
            )
        }
    }
    
    // MARK: - Add to Favorites
    
    func addCurrentTrackToFavorites() {
        guard let ctx = context, let src = localActionTrack else { return }
        let fav = ensureFavorites(in: ctx)
        
        // не дублируем
        if isAlreadyInFavorites(src, favorites: fav) { return }
        
        // клонируем трек (важно: у PlaylistItem deleteRule .cascade, поэтому лучше делать копию)
        let copy = cloneTrack(src)
        let nextIndex = (fav.items.map(\.sortIndex).max() ?? -1) + 1
        let item = PlaylistItem(sortIndex: nextIndex, playlist: fav, track: copy)
        
        ctx.insert(copy)
        ctx.insert(item)
        fav.updatedAt = .now
        try? ctx.save()
    }
    
    private func ensureFavorites(in ctx: ModelContext) -> LocalPlaylist {
        // ищем защищённый плейлист
        if let existed = try? ctx.fetch(
            FetchDescriptor<LocalPlaylist>(
                predicate: #Predicate { $0.isProtected == true }
            )
        ).first {
            return existed
        }
        // если нет — создаём
        let fav = LocalPlaylist(title: "Favorites", artworkData: nil, createdAt: .now, isProtected: true)
        ctx.insert(fav)
        try? ctx.save()
        return fav
    }
    
    private func isAlreadyInFavorites(_ src: LocalTrack, favorites: LocalPlaylist) -> Bool {
        for it in favorites.items {
            guard let t = it.track else { continue }
            if let a = src.audiusId, !a.isEmpty, a == t.audiusId { return true }
            if let f = src.localFilename, !f.isEmpty, f == t.localFilename { return true }
            if src.title == t.title && src.artist == t.artist { return true }
        }
        return false
    }
    
    private func cloneTrack(_ t: LocalTrack) -> LocalTrack {
        LocalTrack(
            source: t.source,
            title: t.title,
            artist: t.artist,
            duration: t.duration,
            localFilename: t.localFilename,
            localBookmark: t.localBookmark,
            audiusId: t.audiusId,
            artworkURLString: t.artworkURLString,
            artworkThumb: t.artworkThumb
        )
    }
    
    // MARK: - Playing local playlists
    
    @MainActor
    func play(startAt index: Int = 0) async {
        do {
            let entries = try await buildEntries()
            guard !entries.isEmpty else { return }
            PlayerCenter.shared.setQueue(entries, startAt: max(0, min(index, entries.count - 1)), autoplay: true)
        } catch {
            print("play error:", error.localizedDescription)
        }
    }
    
    @MainActor
    func play() async { await play(startAt: 0) }
    
    // Собираем очередь из актуальных элементов плейлиста
    private func buildEntries() async throws -> [PlayerQueueEntry] {
        // строго по sortIndex
        let ordered = items.sorted { $0.sortIndex < $1.sortIndex }
        var result: [PlayerQueueEntry] = []
        result.reserveCapacity(ordered.count)
        
        for it in ordered {
            guard let t = it.track else { continue }
            do {
                let url = try await resolveURL(for: t)
                let meta = NowPlayingMeta(
                    title: t.title,
                    artist: t.artist,
                    artworkURL: URL(string: t.artworkURLString ?? "")
                )
                let entry = PlayerQueueEntry(id: t.audiusId ?? t.id.uuidString, url: url, meta: meta)
                result.append(entry)
            } catch {
                // пропускаем неразрешившиеся элементы
                print("skip track resolve error:", error.localizedDescription)
            }
        }
        return result
    }
    
    // Разрешаем URL для локального/аудиус трека
    private func resolveURL(for t: LocalTrack) async throws -> URL {
        switch t.source {
        case .localFile:
            if let name = t.localFilename, !name.isEmpty {
                return try urlInContainer(filename: name)
            }
            if let bm = t.localBookmark {
                var stale = false
                let url = try URL(
                    resolvingBookmarkData: bm,
                    options: [.withoutUI],
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                )
                return url
            }
            throw URLError(.fileDoesNotExist)
            
        case .audius:
            guard let id = t.audiusId, !id.isEmpty else { throw URLError(.badURL) }
            // если у тебя streamURL синхронный — убери await:
            let url = try await api.streamURL(for: id)
            return url
        }
    }
    
    // Строим путь к Library/Audio/<filename>
    private func urlInContainer(filename: String) throws -> URL {
        let fm = FileManager.default
        let lib = try fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return lib.appendingPathComponent("Audio", isDirectory: true).appendingPathComponent(filename, conformingTo: .audio)
    }
    
}
