import SwiftUI
import Kingfisher

struct TrackActionsSheet: View {
    let isLocal: Bool
    let track: MyTrack
    /// Можно прокинуть фолбэк-URL из VM (например, viewModel.coverURL(for: track))
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
                    dragIndicator()
                        .padding(.bottom, 20.fitH)

                    HStack(spacing: 12.fitW) {
                        coverView
                            .frame(width: 56.fitW, height: 56.fitH)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 2.fitH) {
                            Text(track.title)
                                .font(.manropeSemiBold(size: 14.fitW))
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            Text(track.artist)
                                .font(.manropeRegular(size: 12.fitW))
                                .foregroundStyle(.gray707070)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 32.fitW)
                    .padding(.bottom, 8.fitH)

                    VStack(spacing: 2.fitH) {
                        if isLocal {
                            actionRow(symbol: "sheetLikeIcon", title: "Like", action: onLike)
//                            actionRow(symbol: "sheetMusicnoteIcon", title: "Add to Playlist", action: onAddToPlaylist)
                            actionRow(symbol: "sheetForwardIcon", title: "Play Next", action: onPlayNext)
                            actionRow(symbol: "sheetDownloadIcon", title: "Download", action: onDownload)
                            actionRow(symbol: "sheetShareIcon", title: "Share", action: onShare)
//                            actionRow(symbol: "sheetRecordCircleIcon", title: "Go to Album", action: onGoToAlbum)
                            actionRow(symbol: "deleteIcon", title: "Remove", action: onRemove)
                        } else {
                            actionRow(symbol: "sheetLikeIcon", title: "Like", action: onLike)
//                            actionRow(symbol: "sheetMusicnoteIcon", title: "Add to Playlist", action: onAddToPlaylist)
                            actionRow(symbol: "sheetForwardIcon", title: "Play Next", action: onPlayNext)
                            actionRow(symbol: "sheetDownloadIcon", title: "Download", action: onDownload)
                            actionRow(symbol: "sheetShareIcon", title: "Share", action: onShare)
//                            actionRow(symbol: "sheetRecordCircleIcon", title: "Go to Album", action: onGoToAlbum)
                        }
                    }
                    .padding(.horizontal, 32.fitW)
                }
                .padding(.top, 8.fitH)
            }
    }

    @ViewBuilder
    private var coverView: some View {
        if let url = coverURL ?? track.artworkURL {
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

    private func dragIndicator() -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(.gray707070)
            .frame(width: 33.fitW, height: 3)
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
