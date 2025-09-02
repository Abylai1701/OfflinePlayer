import SwiftUI

enum Tab: Hashable { case home, playlists, settings }

struct RootView: View {
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var player: PlayerCenter
    @State private var showFullPlayer = false
    
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
                PlaylistView()
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
                SettingsView()
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
        .onAppear {
            TabBarAppearanceConfigurator.apply()
        }
        .toolbar(.visible, for: .tabBar)
        
        .safeAreaInset(edge: .bottom) {
            if let entry = player.currentEntry {
                MiniPlayerBarRemote(
                    coverURL: entry.meta.artworkURL,
                    title: entry.meta.title,
                    subtitle: entry.meta.artist,
                    onExpand: { showFullPlayer = true },
                    onPlay: { player.play() },
                    onPause: { player.pause() }
                )
                
                .padding(.bottom, 44)

            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showFullPlayer) {
            if let e = player.currentEntry {
                // MusicPlayerView у тебя сейчас принимает Image — можно дать плейсхолдер,
                // а при желании позже сделать версию с URL.
                MusicPlayerView(
                    cover: Image(.cover),
                    title: e.meta.title,
                    artist: e.meta.artist,
                    onDismiss: { showFullPlayer = false }
                )
                .environmentObject(router)
            }
        }
    }
}
