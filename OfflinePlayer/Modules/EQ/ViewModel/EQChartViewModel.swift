//
//  EQChartViewModel.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 21.08.2025.
//
import SwiftUI

@MainActor
final class EQChartViewModel: ObservableObject {
    // MARK: Router
    private weak var router: Router?
    
    func attach(router: Router) {
        self.router = router
    }
    func back() {
        router?.pop()
    }
}
