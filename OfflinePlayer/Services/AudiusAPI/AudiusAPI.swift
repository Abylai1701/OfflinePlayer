//
//  AudiusAPI.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 19.08.2025.
//

import Foundation

@MainActor
final class AudiusAPI {
    
    private let host: AudiusHostProvider
    private let appName: String

    private struct Envelope<Payload: Decodable>: Decodable {
        let data: Payload
    }

    init(host: AudiusHostProvider, appName: String) {
        self.host = host
        self.appName = appName
    }

    // MARK: - Публичные методы (минимально нужные)
    func trendingPlaylists(time: TimeWindow, limit: Int = 20, offset: Int = 0) async throws -> [MyPlaylist] {
        try await call("/v1/playlists/trending", query: [
            "time": time.rawValue, "limit": "\(limit)", "offset": "\(offset)"
        ])
    }

    func trendingTracks(time: TimeWindow, genre: AudiusGenre? = nil, limit: Int = 20, offset: Int = 0) async throws -> [MyTrack] {
        var q: [String: String] = ["time": time.rawValue, "limit": "\(limit)", "offset": "\(offset)"]
        if let g = genre { q["genre"] = g.rawValue }
        return try await call("/v1/tracks/trending", query: q)
    }

    func playlistTracks(id: String, limit: Int = 100, offset: Int = 0) async throws -> [MyTrack] {
        try await call("/v1/playlists/\(id)/tracks", query: ["limit": "\(limit)", "offset": "\(offset)"])
    }

    func searchPlaylists(_ query: String, limit: Int = 20, offset: Int = 0) async throws -> [MyPlaylist] {
        try await call("/v1/playlists/search", query: ["query": query, "limit": "\(limit)", "offset": "\(offset)"])
    }

    func searchTracks(_ query: String, limit: Int = 20, offset: Int = 0) async throws -> [MyTrack] {
        try await call("/v1/tracks/search", query: ["query": query, "limit": "\(limit)", "offset": "\(offset)"])
    }

    func streamURL(for trackId: String) throws -> URL {
        try ensureBase().appending(queryItems: [
            URLQueryItem(name: "app_name", value: appName)
        ], path: "/v1/tracks/\(trackId)/stream")
    }

    // MARK: - Внутренности

    private func call<T: Decodable>(_ path: String, query: [String: String]) async throws -> [T] {
        try await host.ensureHost()
        let url1 = try ensureBase().appending(queryItems: (query + ["app_name": appName]).map(URLQueryItem.init(name:value:)), path: path)
        do {
            let (data, resp) = try await URLSession.shared.data(from: url1)
            try validate(resp)
            return try decodeWrapped([T].self, from: data)
        } catch {
            try await host.refreshHost()
            let url2 = try ensureBase().appending(queryItems: (query + ["app_name": appName]).map(URLQueryItem.init(name:value:)), path: path)
            let (data2, resp2) = try await URLSession.shared.data(from: url2)
            try validate(resp2)
            return try decodeWrapped([T].self, from: data2)
        }
    }

    private func ensureBase() throws -> URL {
        guard let base = host.baseURL else { throw URLError(.badURL) }
        return base
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private func decodeWrapped<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(Envelope<T>.self, from: data).data
    }
}

private extension Dictionary where Key == String, Value == String {
    static func + (lhs: Self, rhs: Self) -> Self {
        var d = lhs; rhs.forEach { d[$0] = $1 }; return d
    }
}
private extension URL {
    func appending(queryItems: [URLQueryItem], path: String) throws -> URL {
        var base = self
        base.append(path: path)
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        comps.queryItems = (comps.queryItems ?? []) + queryItems
        guard let u = comps.url else { throw URLError(.badURL) }
        return u
    }
}
