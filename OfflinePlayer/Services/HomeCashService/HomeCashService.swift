//
//  HomeCashService.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 21.08.2025.
//

import Foundation

@MainActor
final class HomeCacheService: ObservableObject {
    static let shared = HomeCacheService()

    private let host = AudiusHostProvider()
    private lazy var api = AudiusAPI(host: host, appName: "OfflineOlen", logLevel: .info)

    @Published private(set) var feeds: [HomeCategory: HomeFeed] = [:]
    @Published private(set) var lastRefresh: Date?

    func feed(for category: HomeCategory) -> HomeFeed? {
        feeds[category]
    }

    func refreshAll() async {
        do {
            try await host.ensureHost()
            let cats = HomeCategory.allCases.filter { $0 != .favorites }
            var tmp: [HomeCategory: HomeFeed] = [:]

            try await withThrowingTaskGroup(of: (HomeCategory, HomeFeed).self) { group in
                for c in cats {
                    group.addTask { [api] in
                        let time = c.timeWindow
                        let genre = c.genre

                        async let p: [MyPlaylist] = api.trendingPlaylists(time: time, limit: 20)
                        async let t: [MyTrack] = api.trendingTracks(time: time, genre: genre, limit: 20)
                        let (playlists, tracks) = try await (p, t)

                        let playlistCovers = try await Self.buildPlaylistCovers(api: api, playlists: playlists)
                        let trackCovers = Dictionary(uniqueKeysWithValues: tracks.compactMap { tr in
                            tr.artworkURL.map { (tr.id, $0) }
                        })

                        return (c, HomeFeed(
                            playlists: playlists,
                            tracks: tracks,
                            playlistCovers: playlistCovers,
                            trackCovers: trackCovers
                        ))
                    }
                }
                for try await (c, feed) in group { tmp[c] = feed }
            }

            self.feeds = tmp
            
            let allPlaylists = tmp.values.flatMap {
                $0.playlists
            }
            let allTracks = tmp.values.flatMap {
                $0.tracks
            }
            LocalLibrary.shared.replace(tracks: allTracks, playlists: allPlaylists)
            
            self.lastRefresh = Date()
        } catch {
            print("refreshAll error:", error.localizedDescription)
        }
    }

    /// Обновить, только если кэш старше maxAge (например, 15 минут)
    func ensureFresh(maxAge: TimeInterval) async {
        if let d = lastRefresh, Date().timeIntervalSince(d) < maxAge { return }
        await refreshAll()
    }

    private static func buildPlaylistCovers(api: AudiusAPI, playlists: [MyPlaylist]) async throws -> [String: URL] {
        var dict: [String: URL] = [:]
        await withTaskGroup(of: (String, URL?).self) { group in
            for p in playlists {
                group.addTask {
                    if let u = p.artworkURL { return (p.id, u) }
                    if let u = p.user?.profilePicture?._1000x1000
                        ?? p.user?.profilePicture?._480x480
                        ?? p.user?.profilePicture?._150x150 { return (p.id, u) }
                    if let first = try? await api.playlistTracks(id: p.id, limit: 3).first,
                       let u = first.artworkURL { return (p.id, u) }
                    return (p.id, nil)
                }
            }
            for await (id, url) in group { if let u = url { dict[id] = u } }
        }
        return dict
    }
}
