//
//  TrackActionSheetView.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 12.08.2025.
//

import SwiftUI

struct TrackActionsSheet: View {
    let track: Track

    var onLike: () -> Void
    var onAddToPlaylist: () -> Void
    var onPlayNext: () -> Void
    var onDownload: () -> Void
    var onShare: () -> Void
    var onGoToAlbum: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .frame(width: 40, height: 4)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.top, 8)

            // Хедер карточки
            HStack(spacing: 12) {
                track.cover
                    .resizable().scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.manropeSemiBold(size: 18)).foregroundStyle(.white)
                    Text(track.artist).font(.manropeRegular(size: 15)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            Divider().background(.white.opacity(0.1))

            // Список действий
            VStack(spacing: 2) {
                actionRow(symbol: "heart", title: "Like", action: onLike)
                actionRow(symbol: "music.note.list", title: "Add to Playlist", action: onAddToPlaylist)
                actionRow(symbol: "play.fill", title: "Play Next", action: onPlayNext)
                actionRow(symbol: "arrow.down.circle", title: "Download", action: onDownload)
                actionRow(symbol: "square.and.arrow.up", title: "Share", action: onShare)
                actionRow(symbol: "rectangle.stack", title: "Go to Album", action: onGoToAlbum)
                actionRow(symbol: "trash", title: "Remove", action: onRemove)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.96))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func actionRow(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 28, alignment: .leading)
                    .foregroundStyle(.white)

                Text(title)
                    .font(.manropeRegular(size: 17))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

