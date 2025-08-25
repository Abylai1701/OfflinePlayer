//
//  LocalStorage.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 23.08.2025.
//

import Foundation
import AVFoundation

struct LocalPlaylistsConfig {
    /// Копировать выбранный пользователем файл в контейнер приложения (Library/Audio)
    /// Если false — будет сохранён security-bookmark (iOS: без .withSecurityScope).
    var copyFilesIntoContainer: Bool = true
    var useBookmarksForLocalFiles: Bool = false
}

// MARK: - Local storage helper (Library/Audio)

enum LocalStore {
    static func audioDir() throws -> URL {
        let base = try FileManager.default.url(for: .libraryDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let dir = base.appendingPathComponent("Audio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func importFile(from sourceURL: URL) throws -> URL {
        let dstDir = try audioDir()
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let name = UUID().uuidString + "." + ext
        let dst = dstDir.appendingPathComponent(name)
        try FileManager.default.copyItem(at: sourceURL, to: dst)
        return dst
    }

    static func urlInContainer(filename: String) throws -> URL {
        try audioDir().appendingPathComponent(filename)
    }
}

// MARK: - Metadata

struct AudioMeta {
    var title: String?
    var artist: String?
    var duration: Double?
    var artworkData: Data?
}

enum AudioMetadata {
    static func extract(from url: URL) -> AudioMeta {
        let asset = AVURLAsset(url: url)
        let dur = asset.duration.isNumeric ? CMTimeGetSeconds(asset.duration) : nil

        var title: String?
        var artist: String?
        var artData: Data?

        for item in asset.commonMetadata {
            guard let key = item.commonKey?.rawValue else { continue }
            switch key {
            case "title":  title  = item.stringValue ?? title
            case "artist": artist = item.stringValue ?? artist
            case "artwork":
                if let data = item.dataValue { artData = data }
            default: break
            }
        }
        return .init(title: title, artist: artist, duration: dur, artworkData: artData)
    }
}
