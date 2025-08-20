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
    @StateObject private var viewModel = MainViewModel()
    
    @State private var search = ""
    @State private var category: HomeCategory = .popular
    
    var body: some View {
        let blurOn = viewModel.isActionSheetPresented
        
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: .zero) {
                Text("Home")
                    .font(.manropeBold(size: 24.fitW))
                    .padding(.top)
                    .padding(.horizontal)
                    .foregroundStyle(.white)
                    .padding(.bottom)
                
                ScrollView {
                    MainSearchView(searchText: search)
                    
                    CategoryTabs(selection: $category)
                        .padding(.top, 4.fitH)
                        .padding(.bottom, 24.fitH)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16.fitH) {
                            ForEach(viewModel.heroPlaylists) { p in
                                PlaylistCardRemote(
                                    coverURL: viewModel.coverURL(for: p),   // <— вместо p.artworkURL
                                    title: p.title,
                                    subtitle: p.user?.name ?? p.user?.handle ?? ""
                                ) {
                                    viewModel.pushToDetail()
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
                                onMenuTap: { viewModel.openActions(for: t) }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100.fitH)
                }
            }
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
                await viewModel.bootstrap(initial: category)
            }
            .onChange(of: category) { _, newValue in
                Task { await viewModel.setCategory(newValue) }
            }
        }
        .animation(nil, value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView().controlSize(.large)
            } else if let err = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Ошибка").bold().foregroundStyle(.white)
                    Text(err).font(.footnote).multilineTextAlignment(.center)
                    Button("Повторить") { Task { await viewModel.setCategory(category) } }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .sheet(isPresented: $viewModel.isActionSheetPresented) {
            if let t = viewModel.actionTrack {
                TrackActionsSheet(
                    track: t,
                    coverURL: viewModel.coverURL(for: t),   // ← фолбэк из VM (если делаешь)
                    onLike: {
                        viewModel.like();
                        viewModel.closeActions()
                    },
                    onAddToPlaylist: {
                        viewModel.addToPlaylist();
                        viewModel.closeActions()
                    },
                    onPlayNext: {
                        viewModel.playNext();
                        viewModel.closeActions()
                    },
                    onDownload: {
                        viewModel.download();
                        viewModel.closeActions()
                    },
                    onShare: {
                        viewModel.share();
                        viewModel.closeActions()
                    },
                    onGoToAlbum: {
                        viewModel.goToAlbum();
                        viewModel.closeActions()
                    },
                    onRemove: {
                        viewModel.remove();
                        viewModel.closeActions()
                    }
                )
                .presentationDetents([.height(462)])
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(Router())
}
