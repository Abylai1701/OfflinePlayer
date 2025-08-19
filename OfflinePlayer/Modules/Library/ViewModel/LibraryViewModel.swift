//
//  SearchInLibraryViewModel.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 19.08.2025.
//
import SwiftUI

final class LibraryViewModel: ObservableObject {
    
    private weak var router: Router?
    
    @Published private(set) var items: [LibraryTrack] = [
        .init(title: "Fireproof Heart",  artist: "Novaa",           cover: Image(.image)),
        .init(title: "Pretty",           artist: "Inga Klaus",      cover: Image(.image)),
        .init(title: "Hello",            artist: "Nova Wren",       cover: Image(.image)),
        .init(title: "Midnight Carousel",artist: "The Amber Skies", cover: Image(.image)),
        .init(title: "Runaway Signal",   artist: "KERO & Flashline",cover: Image(.image)),
        .init(title: "Mirror Maze",      artist: "Arlo Mav",        cover: Image(.image)),
        .init(title: "No Sleep City",    artist: "Drex Malone",     cover: Image(.image)),
        .init(title: "Hello",            artist: "—",               cover: Image(.image))
    ]
    
    func attach(router: Router) {
        self.router = router
    }
    @MainActor func back() {
        router?.pop()
    }
    
    func filtered(by query: String) -> [LibraryTrack] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q) }
    }
    
    func addToPlaylist(_ t: LibraryTrack) {
        print("Add \(t.title) to playlist")
    }
}
