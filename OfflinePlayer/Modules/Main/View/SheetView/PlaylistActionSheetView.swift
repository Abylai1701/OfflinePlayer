import SwiftUI

struct PlaylistActionsSheet: View {
    var onShare: () -> Void
    var onRename: () -> Void
    var onAddTrack: () -> Void
    var onDelete: () -> Void

    @Binding var idealHeight: CGFloat

    var body: some View {
        VStack(spacing: 10.fitH) {
            Capsule()
                .frame(width: 40.fitW, height: 4)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.top, 8.fitH)

            VStack(spacing: 2.fitH) {
                row(symbol: "Share", title: "Share Playlist",  action: onShare)
                row(symbol: "Pen",               title: "Rename Playlist", action: onRename)
                row(symbol: "Add",                 title: "Add track",       action: onAddTrack)
                row(symbol: "Delete",                title: "Delete Playlist", action: onDelete, tint: .red)
            }
            .padding(.horizontal, 16.fitW)

            // небольшой «воздух» снизу внутри шита
            Color.clear.frame(height: 6.fitH)
        }
        .padding(.bottom, 6.fitH)
        .background(.black191919)
        .reportHeight($idealHeight) // замеряем общую высоту контента
    }

    @ViewBuilder
    private func row(symbol: String, title: String, action: @escaping () -> Void, tint: Color = .white) -> some View {
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
