//
//  Router.swift
//  WeatherPoetry
//
//  Created by Abylaikhan Abilkayr on 27.07.2025.
//


enum AppRoute: Hashable {
    case main
    case trendingNow(items: [MyTrack])
    case playlists
    case playlistDetails(playlist: MyPlaylist, items: [MyTrack])
    case localPlaylist(playlist: LocalPlaylist)
    case library(playlist: LocalPlaylist)
}

import SwiftUI

@MainActor
final class Router: ObservableObject {
    @Published var selectedTab: Tab = .home

    @Published var homePath = NavigationPath()
    @Published var playlistsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()

    // MARK: - Helpers
    func push(_ route: AppRoute, in tab: Tab? = nil) {
        switch tab ?? selectedTab {
        case .home: homePath.append(route)
        case .playlists: playlistsPath.append(route)
        case .settings: settingsPath.append(route)
        }
    }

    func pop(in tab: Tab? = nil) {
        switch tab ?? selectedTab {
        case .home: if !homePath.isEmpty { homePath.removeLast() }
        case .playlists: if !playlistsPath.isEmpty { playlistsPath.removeLast() }
        case .settings:  if !settingsPath.isEmpty  { settingsPath.removeLast() }
        }
    }

    func popToRoot(in tab: Tab? = nil) {
        switch tab ?? selectedTab {
        case .home: homePath.removeLast(homePath.count)
        case .playlists: playlistsPath.removeLast(playlistsPath.count)
        case .settings: settingsPath.removeLast(settingsPath.count)
        }
    }
}

extension Router {
    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .main:
            MainView()
        case .trendingNow(let items):
            TrendingNowView(items: items)
        case .playlists:
            PlaylistView()
        case .playlistDetails(let playlist, let items):
            PlaylistDetailsView(tracks: items, playlist: playlist)
        case .library(playlist: let playlist):
            LibraryView(playlist: playlist)
        case .localPlaylist(playlist: let playlist):
            LocalPlaylistDetailView(playlist: playlist)
        }
    }
}
