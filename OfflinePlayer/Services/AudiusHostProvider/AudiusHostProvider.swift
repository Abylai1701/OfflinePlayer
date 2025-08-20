//
//  AudiusHostProvider.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 19.08.2025.
//

import Foundation

@MainActor
final class AudiusHostProvider: ObservableObject {
    
    @Published private(set) var baseURL: URL?

    func ensureHost() async throws {
        if baseURL == nil {
            try await refreshHost()
        }
    }

    func refreshHost() async throws {
        let url = URL(string: "https://api.audius.co")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let list = try JSONDecoder().decode(Hosts.self, from: data).data
        guard let raw = list.randomElement(), let u = URL(string: raw) else {
            throw URLError(.badServerResponse)
        }
        baseURL = u
    }

    private struct Hosts: Decodable {
        let data: [String]
    }
}
