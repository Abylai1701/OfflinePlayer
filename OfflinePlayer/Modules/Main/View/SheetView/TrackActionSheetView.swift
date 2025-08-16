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
    
    @Binding var idealHeight: CGFloat
    
    
    var body: some View {
        VStack(spacing: 16.fitH) {
            
            HStack(spacing: 12.fitW) {
                track.cover
                    .resizable().scaledToFill()
                    .frame(width: 56.fitW, height: 56.fitH)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2.fitH) {
                    Text(track.title).font(.manropeSemiBold(size: 18.fitW)).foregroundStyle(.white)
                    Text(track.artist).font(.manropeRegular(size: 15.fitW)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(.top, 10.fitH)
            .padding(.horizontal, 16.fitW)
            
            
            Divider().background(.white.opacity(0.1))
            
            VStack(spacing: 2.fitH) {
                actionRow(symbol: "Like", title: "Like", action: onLike)
                actionRow(symbol: "Musicnote", title: "Add to Playlist", action: onAddToPlaylist)
                actionRow(symbol: "Forward", title: "Play Next", action: onPlayNext)
                actionRow(symbol: "Download", title: "Download", action: onDownload)
                actionRow(symbol: "Share", title: "Share", action: onShare)
                actionRow(symbol: "Record-crcle", title: "Go to Album", action: onGoToAlbum)
                actionRow(symbol: "Delete", title: "Remove", action: onRemove)
            }
            .padding(.horizontal, 16.fitW)
            Color.clear.frame(height: 6.fitH)
        }
        .padding(.top, 8.fitH)
        .background(.black191919)
        .reportHeight($idealHeight)
    }
    
    private func actionRow(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14.fitW) {
                Image(symbol)
                    .font(.system(size: 20.fitW, weight: .semibold))
                    .frame(width: 28.fitW, alignment: .leading)
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.manropeSemiBold(size: 17.fitW))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.vertical, 12.fitH)
        }
        .buttonStyle(.plain)
    }
}
