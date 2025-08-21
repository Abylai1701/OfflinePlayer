//
//  PlaylistCard.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 20.08.2025.
//

import SwiftUI
import Kingfisher

struct PlaylistCardRemote: View {
    let coverURL: URL?
    let title: String
    let subtitle: String
    var onTap: () -> Void = {}

    var body: some View {
        Button(
            action: onTap
        ) {
            VStack(alignment: .leading, spacing: .zero) {
                KFImage(coverURL)
                    .placeholder { Color.gray.opacity(0.2) }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 152.fitW, height: 152.fitW)))
                    .cacheOriginalImage()
                    .loadDiskFileSynchronously()
                    .fade(duration: 0.15)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 152.fitW, height: 152.fitW)
                    .clipShape(RoundedRectangle(cornerRadius: 22.fitW))

                Text(title)
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                    .padding(.top, 8.fitH)
                    .padding(.bottom, 2.fitH)

                Text(subtitle)
                    .font(.manropeRegular(size: 12.fitW))
                    .foregroundStyle(.gray707070)
            }
            .frame(width: 152.fitW, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
