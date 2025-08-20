//
//  AudiusModels.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 19.08.2025.
//

import Foundation

enum TimeWindow: String {
    case week, month, year, allTime
}

enum AudiusGenre: String {
    case electronic = "Electronic", hipHop = "Hip-Hop", pop = "Pop", jazz = "Jazz"
}


struct MyPlaylist: Decodable, Identifiable, Hashable {
    let id: String
    let playlistName: String
    let isAlbum: Bool?
    let user: User?
    let artwork: Artwork?
    let totalPlayCount: Int?        // было String?

    var title: String { playlistName }

    var artworkURL: URL? {
        artwork?._1000x1000 ?? artwork?._640x ?? artwork?._480x480 ?? artwork?._150x150
    }

    struct User: Decodable, Hashable {
        let handle: String?
        let name: String?
        let profilePicture: Picture?

        struct Picture: Decodable, Hashable {
            let _150x150: URL?
            let _480x480: URL?
            let _1000x1000: URL?

            private enum CodingKeys: String, CodingKey {
                case _150x150 = "150x150"
                case _480x480 = "480x480"
                case _1000x1000 = "1000x1000"
            }
        }
    }

    struct Artwork: Decodable, Hashable {
        let _150x150: URL?
        let _480x480: URL?
        let _640x: URL?        // встречается, например, в cover_photo
        let _1000x1000: URL?

        private enum CodingKeys: String, CodingKey {
            case _150x150 = "150x150"
            case _480x480 = "480x480"
            case _640x     = "640x"
            case _1000x1000 = "1000x1000"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, playlistName, isAlbum, user, artwork, totalPlayCount
    }
}


struct MyTrack: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let duration: Int?                  // было Double?
    let user: User?
    let artwork: Artwork?               // было trackArtwork

    var artist: String { user?.name ?? user?.handle ?? "" }
    var artworkURL: URL? {
        artwork?._1000x1000 ?? artwork?._480x480 ?? artwork?._150x150
    }

    struct User: Decodable, Hashable {
        let handle: String?
        let name: String?
        // при желании можно добавить profilePicture как в плейлистах
    }

    struct Artwork: Decodable, Hashable {
        let _150x150: URL?
        let _480x480: URL?
        let _1000x1000: URL?

        private enum CodingKeys: String, CodingKey {
            case _150x150 = "150x150"
            case _480x480 = "480x480"
            case _1000x1000 = "1000x1000"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, user, artwork
        // Если хотите оставить имя trackArtwork:
        // case trackArtwork = "artwork"
    }
}
