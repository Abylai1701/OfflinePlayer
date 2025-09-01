//
//  SwiftDataModels.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 22.08.2025.
//

import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class LocalPlaylist {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var artworkData: Data? // обложка плейлиста (опционально)
    @Relationship(deleteRule: .cascade, inverse: \PlaylistItem.playlist)
    var items: [PlaylistItem] = []

    var isProtected: Bool = false

    init(
        title: String,
        artworkData: Data? = nil,
        createdAt: Date = .now,
        isProtected: Bool = false
    ) {
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.artworkData = artworkData
        self.isProtected = isProtected
    }
}

@Model
final class PlaylistItem {
    @Attribute(.unique) var id: UUID = UUID()
    var sortIndex: Int
    @Relationship var playlist: LocalPlaylist?
    @Relationship(deleteRule: .cascade) var track: LocalTrack?

    init(sortIndex: Int, playlist: LocalPlaylist, track: LocalTrack) {
        self.sortIndex = sortIndex
        self.playlist = playlist
        self.track = track
    }
}

enum TrackSource: Int, Codable {
    case localFile
    case audius
}

@Model
final class LocalTrack {
    @Attribute(.unique) var id: UUID = UUID()
    var sourceRaw: Int // TrackSource
    var title: String
    var artist: String
    var duration: Double? // seconds

    // Локальный файл (вариант 1 — копия в контейнер)
    var localFilename: String? // хранится только имя файла в Library/Audio

    // Локальный файл (вариант 2 — bookmark, если включишь конфиг)
    var localBookmark: Data?

    // Для Audius
    var audiusId: String?
    var artworkURLString: String?

    // Маленький thumbnail, если вытащили из файла
    var artworkThumb: Data?

    init(source: TrackSource,
         title: String,
         artist: String,
         duration: Double?,
         localFilename: String? = nil,
         localBookmark: Data? = nil,
         audiusId: String? = nil,
         artworkURLString: String? = nil,
         artworkThumb: Data? = nil)
    {
        self.sourceRaw = source.rawValue
        self.title = title
        self.artist = artist
        self.duration = duration
        self.localFilename = localFilename
        self.localBookmark = localBookmark
        self.audiusId = audiusId
        self.artworkURLString = artworkURLString
        self.artworkThumb = artworkThumb
    }

    var source: TrackSource { TrackSource(rawValue: sourceRaw) ?? .localFile }
}
