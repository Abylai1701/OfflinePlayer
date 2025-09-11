//
//  APISearchTrackRow.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 12.09.2025.
//

import Foundation
import SwiftUI
import Kingfisher

struct APISearchTrackRow: View {
    
    // MARK: - Properties
    
    let coverURL: URL?
    let title: String
    let artist: String
    var onAdd: () -> Void
    
    // MARK: - Body

    var body: some View {
        HStack(spacing: 12.fitW) {
            KFImage(coverURL)
                .placeholder { Color.gray.opacity(0.2) }
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .resizable()
                .scaledToFill()
                .frame(width: 60.fitW, height: 60.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 14.fitW, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title)
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(artist)
                    .font(.manropeRegular(size: 12.fitW))
                    .foregroundStyle(.gray707070)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.manropeSemiBold(size: 18.fitW))
                    .frame(width: 18.fitW, height: 18.fitW)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
    }
}
