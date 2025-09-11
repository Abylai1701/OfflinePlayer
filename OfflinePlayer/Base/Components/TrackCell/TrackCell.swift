//
//  TrackCell.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 20.08.2025.
//

import SwiftUI
import Kingfisher

struct TrackCell: View {
    
    var rank: Int? = nil
    let coverURL: URL?
    let title: String
    let artist: String
    var onMenuTap: () -> Void = {}

    init(
        rank: Int? = nil,
        coverURL: URL?,
        title: String,
        artist: String,
        onMenuTap: @escaping () -> Void = {}
    ) {
        self.rank = rank
        self.coverURL = coverURL
        self.title = title
        self.artist = artist
        self.onMenuTap = onMenuTap
    }

    var body: some View {
        HStack(spacing: .zero) {
            
            if let r = rank {
                VStack(spacing: 6.fitH) {
                    Text("\(r)").font(.manropeSemiBold(size: 20.fitW)).foregroundStyle(.white)
                    Capsule().frame(width: 14.fitW, height: 2.fitH).foregroundStyle(.white)
                }
                .frame(width: 30.fitW).padding(.trailing, 8)
            } else {
                Spacer().frame(width: 6.fitW)
            }

            KFImage(coverURL)
                .placeholder { Color.gray.opacity(0.2) }
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 60.fitW, height: 60.fitW)))
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .fade(duration: 0.15)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .frame(width: 60.fitW, height: 60.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title).font(.manropeSemiBold(size: 14.fitW)).foregroundStyle(.white)
                Text(artist).font(.manropeRegular(size: 12.fitW)).foregroundStyle(.gray707070)
            }
            .padding(.leading, 10.fitW)

            Spacer(minLength: 12)
            Button(action: onMenuTap) { Image(systemName: "ellipsis").font(.manropeSemiBold(size: 18.fitW)).foregroundStyle(.white) }
                .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
