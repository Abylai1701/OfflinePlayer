//
//  MainView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 11.08.2025.
//

import Foundation
import SwiftUI
import Kingfisher

struct MainView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = MainViewModel()
    
    @State private var search = ""
    @State private var category: HomeCategory = .popular
    
    var body: some View {
        let blurOn = viewModel.isActionSheetPresented
        
        ZStack {
            background
            content
                .ignoresSafeArea(.container, edges: .bottom)
                .compositingGroup()
                .blur(radius: blurOn ? 20 : 0)
                .animation(.easeInOut(duration: 0.3), value: blurOn)
                .scrollIndicators(.hidden)
                .onTapGesture {
                    UIApplication.shared.endEditing(true)
                }
                .task {
                    viewModel.attach(router: router)
                    viewModel.bindIfNeeded(context: modelContext)
                    await viewModel.bootstrap(initial: category)
                }
                .onChange(of: category) { _, newValue in
                    Task {
                        await viewModel.setCategory(newValue)
                    }
                }
        }
        .animation(nil, value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .foregroundStyle(.blue007AFF)
            } else if let err = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Ошибка").bold()
                        .foregroundStyle(.white)
                    Text(err)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    Button("Повторить") {
                        Task { await viewModel.setCategory(category)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .allowsHitTesting(!viewModel.isLoading)
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            ShareSheet(items: viewModel.shareItems)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.isActionSheetPresented) {
            if let t = viewModel.actionTrack {
                TrackActionsSheet(
                    isLocal: false,
                    track: t,
                    coverURL: viewModel.coverURL(for: t),
                    onLike: {
                        viewModel.isActionSheetPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            viewModel.addCurrentTrackToFavorites()
                        }
                    },
                    onPlayNext: {
                        viewModel.playNext();
                        viewModel.closeActions()
                    },
                    onDownload: {
                        viewModel.download(t);
                        viewModel.closeActions()
                    },
                    onShare: {
                        viewModel.isActionSheetPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            viewModel.shareCurrentTrack()
                        }
                    },
                    onRemove: {
                        viewModel.remove();
                        viewModel.closeActions()
                    }
                )
                .presentationDetents([.height(290)])
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            }
        }
    }
    
    private var background: some View {
        LinearGradient(
            colors: [.gray222222, .black111111],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("Home")
                .font(.manropeBold(size: 24.fitW))
                .padding(.top)
                .padding(.horizontal)
                .foregroundStyle(.white)
                .padding(.bottom)
            
            scrollView
        }
    }
    
    private var scrollView: some View {
        ScrollView {
            MainSearchView(searchText: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.onSearchTextChanged()
                }
            
            if viewModel.isSearching {
                SearchTabs(selection: $viewModel.searchScope)
                    .padding(.top, 4.fitH)
                    .padding(.bottom, 16.fitH)
                
                // Контент по вкладке
                switch viewModel.searchScope {
                case .all, .top, .tracks:
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.foundTracks, id: \.id) { t in
                            TrackCell(
                                coverURL: t.artworkURL,
                                title: t.title,
                                artist: t.artist,
                                onMenuTap: {
                                    viewModel.openActions(for: t)
                                }
                            )
                            .padding(.horizontal)
                            .onTapGesture {
                                Task {
                                    viewModel.play(t)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 200.fitH)
                    
                case .playlists:
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.foundPlaylists, id: \.id) { p in
                            SearchRowSquare(
                                imageURL: viewModel.coverURL(for: p),
                                title: p.title,
                                subtitle: p.user?.name ?? p.user?.handle ?? ""
                            )
                            .onTapGesture {
                                Task {
                                    await viewModel.openPlaylist(p)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16.fitW)
                    .padding(.bottom, 200.fitH)
                    
                case .album:
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.foundAlbums, id: \.id) { p in
                            SearchRowSquare(
                                imageURL: viewModel.coverURL(for: p),
                                title: p.title,
                                subtitle: p.user?.name ?? p.user?.handle ?? ""
                            )
                        }
                    }
                    .padding(.horizontal, 16.fitW)
                    .padding(.bottom, 200.fitH)
                    
                case .singer:
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.foundArtists, id: \.self) { name in
                            SearchRowCircle(
                                imageURL: nil, // позже — аватар из твоего хранилища
                                title: name
                            )
                        }
                    }
                    .padding(.horizontal, 16.fitW)
                    .padding(.bottom, 200.fitH)
                }
                
            } else {
                CategoryTabs(selection: $category)
                    .padding(.top, 4.fitH)
                    .padding(.bottom, 24.fitH)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16.fitH) {
                        ForEach(viewModel.heroPlaylists) { p in
                            PlaylistCardRemote(
                                coverURL: viewModel.coverURL(for: p),
                                title: p.title,
                                subtitle: p.user?.name ?? p.user?.handle ?? ""
                            ) {
                                Task {
                                    await viewModel.openPlaylist(p)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .contentMargins(.horizontal, 16.fitW, for: .scrollContent)
                }
                .padding(.bottom, 26.fitH)
                
                HStack {
                    Text("Trending Now")
                        .font(.manropeBold(size: 20.fitW))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("See all") {
                        viewModel.pushToTrendingNow()
                    }
                    .font(.manropeSemiBold(size: 12.fitW))
                    .foregroundStyle(.grayB3B3B3)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                LazyVStack(spacing: 14) {
                    ForEach(Array(viewModel.trendItems.enumerated()), id: \.element.id) { idx, t in
                        TrackCell(
                            rank: idx + 1,
                            coverURL: t.artworkURL,
                            title: t.title,
                            artist: t.artist,
                            onMenuTap: {
                                viewModel.openActions(for: t)
                            }
                        )
                        .padding(.horizontal)
                        .onTapGesture {
                            Task {
                                viewModel.playAllTrending(startAt: idx)
                            }
                        }
                    }
                }
                .padding(.bottom, 200.fitH)
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(Router())
}


import Kingfisher

struct SearchRowSquare: View {
    let imageURL: URL?
    let title: String
    var subtitle: String = ""
    var body: some View {
        HStack(spacing: 12.fitW) {
            KFImage(imageURL)
                .placeholder { Color.gray.opacity(0.2) }
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .resizable()
                .scaledToFill()
                .frame(width: 56.fitW, height: 56.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title).font(.manropeSemiBold(size: 14.fitW)).foregroundStyle(.white)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.manropeRegular(size: 12.fitW)).foregroundStyle(.gray707070)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct SearchRowCircle: View {
    let imageURL: URL?
    let title: String
    var body: some View {
        HStack(spacing: 12.fitW) {
            KFImage(imageURL)
                .placeholder { Circle().fill(Color.gray.opacity(0.2)) }
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .resizable()
                .scaledToFill()
                .frame(width: 56.fitW, height: 56.fitW)
                .clipShape(Circle())
            Text(title).font(.manropeSemiBold(size: 14.fitW)).foregroundStyle(.white)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
