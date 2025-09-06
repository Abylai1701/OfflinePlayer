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
    case electronic = "", hipHop = "Electronic", pop = "Pop", jazz = "Jazz"
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
    
    var artistAvatarURL: URL? {
        user?.coverPhoto?._640x ?? user?.coverPhoto?._2000x ?? user?.profilePicture?._1000x1000 ?? user?.profilePicture?._480x480 ?? user?.profilePicture?._150x150
    }

    struct User: Decodable, Hashable {
        let handle: String?
        let name: String?
        let coverPhoto: Picture?
        let profilePicture: Artwork?
        
        enum CodingKeys: String, CodingKey {
            case handle, name
            case coverPhoto = "cover_photo"
            case profilePicture = "profile_picture"
            
        }

        struct Picture: Decodable, Hashable {
            let _640x: URL?
            let _2000x: URL?

            private enum CodingKeys: String, CodingKey {
                case _640x = "640x"
                case _2000x = "2000x"
            }
        }
    }

    struct Artwork: Decodable, Hashable {
        let _150x150: URL?
        let _480x480: URL?
        let _640x: URL?
        let _1000x1000: URL?

        private enum CodingKeys: String, CodingKey {
            case _150x150 = "150x150"
            case _480x480 = "480x480"
            case _640x = "640x"
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
    let duration: Int?
    let user: User?
    let artwork: Artwork?

    var artist: String {
        user?.name ?? user?.handle ?? ""
    }
    
    var artworkURL: URL? {
        artwork?._1000x1000 ?? artwork?._480x480 ?? artwork?._150x150
    }
    
    var artistAvatarURL: URL? {
        user?.avatarURL
    }
    
    struct User: Decodable, Hashable {
        let handle: String?
        let name: String?
        let coverPhoto: CoverPhoto?
        let profilePicture: Artwork?
       
        enum CodingKeys: String, CodingKey {
            case handle, name
            case coverPhoto = "cover_photo"
            case profilePicture = "profile_picture"
        }
        
        var avatarURL: URL? {
            profilePicture?.best ?? coverPhoto?.best
                }
    }
    
    struct CoverPhoto: Decodable, Hashable {
        let _640x: URL?
        let _2000x: URL?
        
        enum CodingKeys: String, CodingKey {
            case _640x = "640x"
            case _2000x = "2000x"
        }
        
        var best: URL? { _2000x ?? _640x }
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
        
        var best: URL? { _1000x1000 ?? _480x480 ?? _150x150 }
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, user, artwork
        // Если хотите оставить имя trackArtwork:
        // case trackArtwork = "artwork"
    }
}
