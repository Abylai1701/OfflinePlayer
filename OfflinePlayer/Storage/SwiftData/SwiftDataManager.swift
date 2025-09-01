//
//  SwiftDataManager.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 21.08.2025.
//

import SwiftData
import Foundation
import AVFoundation

@MainActor
final class LocalPlaylistsManager: ObservableObject {

    private let context: ModelContext
    private let config: LocalPlaylistsConfig

    init(context: ModelContext, config: LocalPlaylistsConfig = .init()) {
        self.context = context
        self.config = config
    }

    // MARK: Playlists CRUD

    @discardableResult
    func createPlaylist(title: String, artworkData: Data? = nil, isProtected: Bool = false) -> LocalPlaylist {
        let p = LocalPlaylist(title: title, artworkData: artworkData, createdAt: .now, isProtected: isProtected)
        context.insert(p)
        try? context.save()
        return p
    }

    @discardableResult
    func ensureFavoritesExists(title: String = "Favorites") -> LocalPlaylist {
        if let existing = fetchFavorites() { return existing }
        // можно попробовать найти по названию и пометить защищённым — по простоте просто создаём
        return createPlaylist(title: title, isProtected: true)
    }
    
    func fetchFavorites() -> LocalPlaylist? {
        let predicate = #Predicate<LocalPlaylist> { $0.isProtected == true }
        let descriptor = FetchDescriptor<LocalPlaylist>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    func renamePlaylist(_ playlist: LocalPlaylist, to newTitle: String) {
        playlist.title = newTitle
        playlist.updatedAt = .now
        try? context.save()
    }

    func deletePlaylist(_ playlist: LocalPlaylist) {
        guard playlist.isProtected == false else { return }  // ⬅️ нельзя удалять системный
        context.delete(playlist)
        try? context.save()
    }


    func fetchPlaylists() -> [LocalPlaylist] {
        let byUpdated = SortDescriptor<LocalPlaylist>(\.updatedAt, order: SortOrder.reverse)
        let fetched = (try? context.fetch(FetchDescriptor<LocalPlaylist>(sortBy: [byUpdated]))) ?? []
        // Favorites (isProtected == true) наверх, внутри — по дате
        return fetched.sorted {
            ($0.isProtected ? 1 : 0, $0.updatedAt) > ($1.isProtected ? 1 : 0, $1.updatedAt)
        }
    }
    
    // MARK: Items (Add / Remove / Reorder)

    /// Добавить локальный файл (из DocumentPicker/Photos, etc.)
    @discardableResult
    func addLocalFile(_ pickedURL: URL, to playlist: LocalPlaylist, at index: Int? = nil) throws -> PlaylistItem {
        // На всякий случай — берём доступ если это security-scoped url
        let needsStop = pickedURL.startAccessingSecurityScopedResource()
        defer { if needsStop { pickedURL.stopAccessingSecurityScopedResource() } }

        let localURL: URL
        var bookmark: Data?

        if config.copyFilesIntoContainer {
            localURL = try LocalStore.importFile(from: pickedURL)
        } else {
            // Bookmark (без .withSecurityScope на iOS)
            bookmark = try pickedURL.bookmarkData(options: [],
                                                  includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
            localURL = pickedURL
        }

        // Мета с локального (уже скопированного) URL
        let meta = AudioMetadata.extract(from: localURL)

        let track = LocalTrack(
            source: .localFile,
            title: meta.title ?? localURL.deletingPathExtension().lastPathComponent,
            artist: meta.artist ?? "",
            duration: meta.duration,
            localFilename: config.copyFilesIntoContainer ? localURL.lastPathComponent : nil,
            localBookmark: config.useBookmarksForLocalFiles ? bookmark : nil,
            artworkThumb: meta.artworkData
        )
        context.insert(track)

        let newIndex = index ?? playlist.items.count
        let item = PlaylistItem(sortIndex: newIndex, playlist: playlist, track: track)
        context.insert(item)

        // Сдвигаем sortIndex у остальных при вставке в середину
        if newIndex < playlist.items.count - 1 {
            rebalanceSortIndexes(in: playlist)
        }

        playlist.updatedAt = .now
        try context.save()
        return item
    }

    /// Добавить трек из Audius (метаданные передаёшь из своей модели MyTrack)
    @discardableResult
    func addAudiusTrack(_ t: MyTrack, to playlist: LocalPlaylist, at index: Int? = nil) -> PlaylistItem {
        let track = LocalTrack(
            source: .audius,
            title: t.title,
            artist: t.artist,
            duration: t.duration.map(Double.init),
            audiusId: t.id,
            artworkURLString: t.artworkURL?.absoluteString
        )
        context.insert(track)

        let newIndex = index ?? playlist.items.count
        let item = PlaylistItem(sortIndex: newIndex, playlist: playlist, track: track)
        context.insert(item)

        if newIndex < playlist.items.count - 1 {
            rebalanceSortIndexes(in: playlist)
        }

        playlist.updatedAt = .now
        try? context.save()
        return item
    }

    func removeItem(_ item: PlaylistItem, from playlist: LocalPlaylist) {
        context.delete(item)
        rebalanceSortIndexes(in: playlist)
        playlist.updatedAt = .now
        try? context.save()
    }

    func moveItem(in playlist: LocalPlaylist, from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < playlist.items.count,
              destinationIndex >= 0, destinationIndex <= playlist.items.count
        else { return }

        // Сортируем по sortIndex, затем переставляем и перенумеровываем
        let sorted = playlist.items.sorted(by: { $0.sortIndex < $1.sortIndex })
        var arr = sorted
        let moved = arr.remove(at: sourceIndex)
        arr.insert(moved, at: destinationIndex)

        for (idx, it) in arr.enumerated() {
            it.sortIndex = idx
        }
        playlist.items = arr
        playlist.updatedAt = .now
        try? context.save()
    }

    func rebalanceSortIndexes(in playlist: LocalPlaylist) {
        let arr = playlist.items.sorted(by: { $0.sortIndex < $1.sortIndex })
        for (idx, it) in arr.enumerated() {
            it.sortIndex = idx
        }
        playlist.items = arr
    }

    // MARK: Resolve playable URL

    /// Вернёт URL для локального файла (если копируем в контейнер) либо раскроет bookmark.
    func urlForLocalPlayback(_ track: LocalTrack) -> URL? {
        guard track.source == .localFile else { return nil }

        if let name = track.localFilename, !name.isEmpty {
            return try? LocalStore.urlInContainer(filename: name)
        }

        if let data = track.localBookmark {
            var stale = false
            return try? URL(resolvingBookmarkData: data,
                            options: [.withoutUI],
                            relativeTo: nil,
                            bookmarkDataIsStale: &stale)
        }
        return nil
    }

    /// Удобный хелпер для работы с security-scoped ресурсом (если bookmark указывает на внешний провайдер)
    func withAccess<T>(to track: LocalTrack, _ body: (URL) throws -> T) rethrows -> T? {
        guard let url = urlForLocalPlayback(track) else { return nil }
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        return try body(url)
    }
}
