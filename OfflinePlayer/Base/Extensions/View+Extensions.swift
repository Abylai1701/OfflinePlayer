import SwiftUI

extension View {
    @ViewBuilder
    func applyCustomDetent(height: CGFloat) -> some View {
        if #available(iOS 17, *) {
            self.presentationDetents([.height(height)])
        } else {
            let fraction = max(0.2, min(0.9, height / max(1, UIScreen.main.bounds.height)))
            self.presentationDetents([.fraction(fraction)])
        }
    }
    
    func reportHeight(_ height: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: HeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(HeightKey.self) { height.wrappedValue = $0 }
    }
}
