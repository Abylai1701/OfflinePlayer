import SwiftUI

struct PlaylistActionsSheet: View {
    var onShare: () -> Void
    var onRename: () -> Void
    var onAddTrack: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Rectangle()
            .fill(.gray353434)
            .overlay(alignment: .top) {
                VStack(spacing: .zero) {
                    dragIndicator()
                        .padding(.bottom)
                    
                    VStack(spacing: 2.fitH) {
                        row(symbol: "Share", title: "Share Playlist", action: onShare)
                        row(symbol: "Pen", title: "Rename Playlist", action: onRename)
                        row(symbol: "Add", title: "Add track", action: onAddTrack)
                        row(symbol: "Delete", title: "Delete Playlist", action: onDelete, tint: .red)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 36.fitW)
            }
    }

    private func dragIndicator() -> some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(.white.opacity(0.3))
            .frame(width: 44.fitW, height: 5.fitW)
    }
    
    @ViewBuilder
    private func row(
        symbol: String,
        title: String,
        action: @escaping () -> Void,
        tint: Color = .white
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14.fitW) {
                Image(symbol)
                    .font(.system(size: 20.fitW, weight: .semibold))
                    .frame(width: 28.fitW, alignment: .leading)
                    .foregroundStyle(tint)

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
