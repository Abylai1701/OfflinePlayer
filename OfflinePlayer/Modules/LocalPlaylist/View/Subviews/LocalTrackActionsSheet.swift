//
//  LocalTrackActionsSheet.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 24.08.2025.
//

import SwiftUI
import Kingfisher

struct LocalTrackActionsSheet: View {
    
    let isFavorite: Bool
    
    let title: String
    let artist: String
    var coverURL: URL? = nil

    var onLike: () -> Void
//    var onAddToPlaylist: () -> Void
    var onPlayNext: () -> Void
    var onDownload: () -> Void
    var onShare: () -> Void
//    var onGoToAlbum: () -> Void
    var onRemove: () -> Void

    var body: some View {
        Rectangle()
            .fill(.gray353434)
            .overlay(alignment: .top) {
                VStack(spacing: .zero) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(.gray707070)
                        .frame(width: 33.fitW, height: 3)
                        .padding(.vertical, 12.fitH)

                    HStack(spacing: 12.fitW) {
                        coverView
                            .frame(width: 56.fitW, height: 56.fitH)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 2.fitH) {
                            Text(title).font(.manropeSemiBold(size: 14.fitW)).foregroundStyle(.white)
                            Text(artist).font(.manropeRegular(size: 12.fitW)).foregroundStyle(.gray707070)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24.fitW)
                    .padding(.bottom, 10.fitH)

                    VStack(spacing: 2.fitH) {
                        
                        if isFavorite {
//                            actionRow(symbol: "sheetMusicnoteIcon", title: "Add to Playlist", action: onAddToPlaylist)
                            actionRow(symbol: "sheetForwardIcon", title: "Play Next", action: onPlayNext)
                            actionRow(symbol: "sheetDownloadIcon", title: "Download", action: onDownload)
                            actionRow(symbol: "sheetShareIcon", title: "Share", action: onShare)
                            actionRow(symbol: "deleteIcon", title: "Remove", action: onRemove)
                        } else {
                            actionRow(symbol: "sheetLikeIcon", title: "Like", action: onLike)
//                            actionRow(symbol: "sheetMusicnoteIcon", title: "Add to Playlist", action: onAddToPlaylist)
                            actionRow(symbol: "sheetForwardIcon", title: "Play Next", action: onPlayNext)
                            actionRow(symbol: "sheetDownloadIcon", title: "Download", action: onDownload)
                            actionRow(symbol: "sheetShareIcon", title: "Share", action: onShare)
                            actionRow(symbol: "deleteIcon", title: "Remove", action: onRemove)
                        }
                    }
                    .padding(.horizontal, 24.fitW)
                    .padding(.bottom, 12.fitH)
                }
            }
    }
    
    @ViewBuilder
    private var coverView: some View {
        if let url = coverURL {
            KFImage(url)
                .placeholder { Color.gray.opacity(0.2) }
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 56.fitW, height: 56.fitH)))
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .fade(duration: 0.15)
                .resizable()
                .scaledToFill()
        } else {
            // аккуратный плейсхолдер если вообще нет картинки
            Color.gray.opacity(0.2)
        }
    }
    
    private func actionRow(
        symbol: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14.fitW) {
                Image(symbol)
                    .font(.system(size: 20.fitW, weight: .semibold))
                    .frame(width: 28.fitW, alignment: .leading)
                    .foregroundStyle(.white)

                Text(title)
                    .font(.manropeSemiBold(size: 16.fitW))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.vertical, 12.fitH)
        }
        .buttonStyle(.plain)
    }
}
