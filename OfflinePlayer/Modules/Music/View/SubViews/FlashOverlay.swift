//
//  FlashOverlay.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 12.09.2025.
//

import SwiftUI

struct FlashOverlay: View {
    let event: FlashEvent
    
    var body: some View {
        VStack(spacing: 10) {
            Image(symbol)
                .font(.system(size: 92.fitW, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
        }
        .padding(20)
        .background(.black.opacity(0.001))
    }
    
    private var symbol: String {
        switch event {
        case .likeOn:
            return "favoriteMusicIcon"
        case .likeOff:
            return "notFavoriteMusicIcon"
        case .repeatOne:
            return "repeatMusicIcon"
        case .repeatOff:
            return ""
        case .shuffleOn:
            return "shuffleMusicIcon"
        case .shaffleOff:
            return ""
        }
    }
}
