//
//  OfflinePlayerApp.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 08.08.2025.
//

import SwiftUI

@main
struct WeatherPoetryApp: App {

    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environmentObject(router)
        }
    }
}
