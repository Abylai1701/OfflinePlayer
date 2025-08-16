import SwiftUI

private struct TabBarIsHiddenKey: EnvironmentKey {
    static var defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var tabBarIsHidden: Binding<Bool> {
        get { self[TabBarIsHiddenKey.self] }
        set { self[TabBarIsHiddenKey.self] = newValue }
    }
}
