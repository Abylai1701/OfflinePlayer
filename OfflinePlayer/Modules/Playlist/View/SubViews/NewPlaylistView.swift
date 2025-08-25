//
//  NewPlaylistView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 23.08.2025.
//

import SwiftUI

struct NewPlaylistRow: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10.fitW) {
                RoundedRectangle(cornerRadius: 16.fitW, style: .continuous)
                    .fill(.gray2C2C2C)
                    .frame(width: 60.fitW, height: 60.fitW)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.manropeSemiBold(size: 22.fitW))
                            .frame(width: 18.fitW, height: 18.fitW)
                            .foregroundStyle(.gray707070)
                    }
                
                Text("New Playlist")
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
