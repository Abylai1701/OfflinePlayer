//
//  View+Extensions.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 14.08.2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyCustomDetent(height: CGFloat) -> some View {
        if #available(iOS 17, *) {
            self.presentationDetents([.height(height)])
        } else {
            let fraction = max(0.2, min(0.9, height / max(1, UIScreen.main.bounds.height)))
            self.presentationDetents([.fraction(fraction)])
        }
    }
}

