//
//  OfflinePlayerApp.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 08.08.2025.
//

import SwiftUI
import Kingfisher
import SwiftData

@main
struct OfflinePlayerApp: App {
    
    @StateObject private var router = Router()
    @StateObject private var homeCache = HomeCacheService.shared
    
    init() {
        configureImageCache()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environmentObject(router)
                .environmentObject(PlayerCenter.shared)
                .modelContainer(sharedModelContainer)
                .task {
                    await homeCache.refreshAll()
                }
        }
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocalPlaylist.self,
            LocalTrack.self,
            PlaylistItem.self
        ])
        let config = ModelConfiguration("LocalLibrary")
        return try! ModelContainer(for: schema, configurations: [config])
    }()
    
    
    func configureImageCache() {
        // Память: ~128 MB
        ImageCache.default.memoryStorage.config.totalCostLimit = 128 * 1024 * 1024
        // Диск: ~1 GB, хранить 30 дней
        ImageCache.default.diskStorage.config.sizeLimit = 1_000 * 1024 * 1024
        ImageCache.default.diskStorage.config.expiration = .days(30)
        // URLCache (системный) тоже можно увеличить, но Kingfisher дисковый кеш самодостаточный
    }
}
