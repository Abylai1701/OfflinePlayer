import SwiftUI

enum Tab: Hashable { case home, playlists, settings }

struct RootView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                MainView()
                    .navigationDestination(for: AppRoute.self) { router.destination(for: $0) }

            }
            .tabItem {
                Label {
                    Text("Home")
                } icon: {
                    Image(.homeIcon)
                        .renderingMode(.template)
                }
            }
            .tag(Tab.home)

            NavigationStack(path: $router.playlistsPath) {
                MainView() //Замени потом
                    .navigationDestination(for: AppRoute.self) { router.destination(for: $0) }
            }
            .tabItem {
                Label {
                    Text("Playlists")
                } icon: {
                    Image(.playlistIcon)
                        .renderingMode(.template)
                }
            }
            .tag(Tab.playlists)

            NavigationStack(path: $router.settingsPath) {
                MainView() //Замени потом
                    .navigationDestination(for: AppRoute.self) { router.destination(for: $0) }
            }
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(.settingsIcon)
                        .renderingMode(.template)
                }
            }
            .tag(Tab.settings)
        }
        .toolbarBackground(.clear, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .tint(.white)
        .onAppear { TabBarAppearanceConfigurator.apply() }
    }
}
