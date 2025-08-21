//
//  LocalLibrary.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 21.08.2025.
//

import Foundation

@MainActor
final class LocalLibrary {
    static let shared = LocalLibrary()

    // Здесь будут ТВОИ оффлайн-данные (после загрузок)
    private(set) var tracks: [MyTrack] = []
    private(set) var playlists: [MyPlaylist] = []

    // деривативы
    var albums: [MyPlaylist] { playlists.filter { $0.isAlbum ?? false } }
    var regularPlaylists: [MyPlaylist] { playlists.filter { ($0.isAlbum ?? false) == false } }

    // вызови это, когда у тебя обновится локальная библиотека
    func replace(tracks: [MyTrack], playlists: [MyPlaylist]) {
        self.tracks = tracks
        self.playlists = playlists
    }
}
