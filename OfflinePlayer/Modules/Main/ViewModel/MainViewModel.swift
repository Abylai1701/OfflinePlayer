//
//  MainViewModel.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 11.08.2025.
//

import Foundation

final class MainViewModel: ObservableObject {
    
    private weak var router: Router?
    
    /// Позволяет инжектить Router из View (через .environmentObject)
    func attach(router: Router) {
        self.router = router
    }
    
    @MainActor func pushToTrendingNow() {
        router?.push(.trendingNow)
    }
}
