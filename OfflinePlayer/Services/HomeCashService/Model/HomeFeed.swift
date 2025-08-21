//
//  HomeFeed.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 21.08.2025.
//

import Foundation

struct HomeFeed {
    let playlists: [MyPlaylist]
    let tracks: [MyTrack]
    let playlistCovers: [String: URL] // playlistId -> cover
    let trackCovers: [String: URL]    // trackId    -> cover
}
