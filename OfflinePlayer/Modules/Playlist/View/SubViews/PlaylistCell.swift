//
//  PlaylistCell.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 23.08.2025.
//

import SwiftUI

struct PlaylistCell: View {
    let cover: Image
    let title: String
    let subtitle: String
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10.fitW) {
                cover.resizable().scaledToFill()
                    .frame(width: 60.fitW, height: 60.fitW)
                    .clipShape(RoundedRectangle(cornerRadius: 16.fitW, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2.fitH) {
                    Text(title)
                        .font(.manropeSemiBold(size: 14.fitW))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.manropeRegular(size: 12.fitW))
                        .foregroundStyle(.gray707070)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18.fitW, weight: .semibold))
                    .frame(width: 18.fitW, height: 18.fitW)
                    .foregroundStyle(.white)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
