//
//  MusicPlaingViewModel.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 20.08.2025.
//

import SwiftUI

final class MusicPlayingViewModel: ObservableObject {
    private weak var router: Router?
    
    func attach(router: Router) {
        self.router = router
    }
    
    @MainActor func back() {
        router?.pop()
    }
}
