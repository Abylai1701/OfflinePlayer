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
        // показываем твой общий шит только для аудиус-трека
        isActionSheetPresented = (actionAudiusTrack != nil)
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
            self.rows  = fetched.map { Row.from(item: $0) }
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
            Task { await refresh() }
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

    // MARK: Reorder / Delete

    func move(fromOffsets: IndexSet, toOffset: Int) {
        guard let ctx = context else { return }
        var arr = items
        arr.move(fromOffsets: fromOffsets, toOffset: toOffset)
        // перенумеруем sortIndex
        for (idx, it) in arr.enumerated() { it.sortIndex = idx }
        do {
            try ctx.save()
            self.items = arr
            self.rows  = arr.map { Row.from(item: $0) }
        } catch {
            print("move error:", error.localizedDescription)
        }
    }

    func delete(at offsets: IndexSet) {
        guard let ctx = context else { return }
        do {
            for i in offsets { ctx.delete(items[i]) }
            try ctx.save()
            Task { await refresh() }
        } catch {
            print("delete error:", error.localizedDescription)
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
}
