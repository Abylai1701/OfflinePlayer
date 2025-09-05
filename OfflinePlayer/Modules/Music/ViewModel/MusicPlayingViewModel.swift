//
//  MusicPlaingViewModel.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 20.08.2025.
//

import SwiftUI

@MainActor
final class MusicPlayingViewModel: ObservableObject {
    private weak var router: Router?
    
    func attach(router: Router) {
        self.router = router
    }
    
    func pushToEQ() {
        router?.push(.equalizer)
    }
    
    func back() {
        router?.pop()
    }
}
