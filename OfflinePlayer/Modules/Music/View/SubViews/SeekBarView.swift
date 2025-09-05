import SwiftUI

struct ThinSeekBar: View {
    @Binding var value: Double
    let range: ClosedRange<Double>   
    var trackHeight: CGFloat = 3
    var thumbRadius: CGFloat = 6
    var activeColor: Color = .white
    var inactiveColor: Color = .white.opacity(0.35)
    var onEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let total = range.upperBound - range.lowerBound
            let progress = max(0, min(1, total > 0 ? (value - range.lowerBound) / total : 0))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(inactiveColor)
                    .frame(height: trackHeight)

                Capsule()
                    .fill(activeColor)
                    .frame(width: w * progress, height: trackHeight)

                Circle()
                    .fill(activeColor)
                    .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                    .position(x: w * progress, y: max(trackHeight, thumbRadius * 2))
            }
            .frame(height: max(25, max(trackHeight, thumbRadius * 2)))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        onEditingChanged(true)
                        let x = min(max(0, g.location.x), w)
                        value = range.lowerBound + Double(x / w) * total
                    }
                    .onEnded { _ in onEditingChanged(false) }
            )
        }
        .frame(height: max(44, max(trackHeight, thumbRadius * 2)))
    }
}
