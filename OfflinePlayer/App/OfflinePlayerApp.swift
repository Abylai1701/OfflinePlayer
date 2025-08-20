//
//  OfflinePlayerApp.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 08.08.2025.
//

import SwiftUI
import Kingfisher

@main
struct WeatherPoetryApp: App {

    @StateObject private var router = Router()

    init() {
        configureImageCache()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environmentObject(router)
        }
    }
    

    func configureImageCache() {
        // Память: ~128 MB
        ImageCache.default.memoryStorage.config.totalCostLimit = 128 * 1024 * 1024
        // Диск: ~1 GB, хранить 30 дней
        ImageCache.default.diskStorage.config.sizeLimit = 1_000 * 1024 * 1024
        ImageCache.default.diskStorage.config.expiration = .days(30)
        // URLCache (системный) тоже можно увеличить, но Kingfisher дисковый кеш самодостаточный
    }
}
