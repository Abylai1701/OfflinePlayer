//
//  MainView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 11.08.2025.
//

import Foundation
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = MainViewModel()
    
    @State private var search = ""
    @State private var category: HomeCategory = .popular
    @State private var sheetContentHeight: CGFloat = 430
    
    var body: some View {
        let blurOn = viewModel.isActionSheetPresented
        
        ZStack {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    
                    Text("Home")
                        .font(.manropeBold(size: 24.fitW))
                        .padding(.top)
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                        .padding(.bottom)
                    
                    SearchBar(text: $search)
                    
                    CategoryTabs(selection: $category)
                        .padding(.bottom, 24.fitH)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16.fitH) {
                            ForEach(0..<5) { i in
                                PlaylistCard(
                                    cover: Image(.image),
                                    title: "Playlist \(i+1)",
                                    subtitle: "SZA, Rhye, Mac Miller",
                                    onTap: { viewModel.pushToDetail() }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .contentMargins(.horizontal, 16.fitW, for: .scrollContent)
                    }
                    .padding(.bottom, 26.fitH)
                    
                    HStack {
                        Text("Trending Now")
                            .font(.manropeExtraBold(size: 20.fitW))
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
                    
                    LazyVStack(spacing: 0) {
                        ForEach(1...10, id: \.self) { rank in
                            let t = Track(title: "Track \(rank)", artist: "Artist \(rank)", cover: Image(.image))
                            TrendingRow(
                                rank: rank,
                                cover: t.cover,
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
            }
        }
        .animation(nil, value: viewModel.isActionSheetPresented)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.isActionSheetPresented) {
            if let t = viewModel.actionTrack {
                TrackActionsSheet(
                    track: t,
                    onLike: { viewModel.like(); viewModel.closeActions() },
                    onAddToPlaylist: { viewModel.addToPlaylist(); viewModel.closeActions() },
                    onPlayNext: { viewModel.playNext(); viewModel.closeActions() },
                    onDownload: { viewModel.download(); viewModel.closeActions() },
                    onShare: { viewModel.share(); viewModel.closeActions() },
                    onGoToAlbum: { viewModel.goToAlbum(); viewModel.closeActions() },
                    onRemove: { viewModel.remove(); viewModel.closeActions() }
                )
                .presentationDetents([.height(462)])
                .presentationCornerRadius(28.fitW)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            }
        }
    }
}


enum HomeCategory: String, CaseIterable, Hashable {
    case popular = "Popular", new = "New", trend = "Trend", favorites = "Favorites", relax = "Relax"
}

struct CategoryTabs: View {
    @Binding var selection: HomeCategory
    @Namespace private var underlineNS
    
    var selectedFont: Font = .manropeSemiBold(size: 16.fitW)
    var normalFont: Font = .manropeRegular(size: 16.fitW)
    
    private let baseLineLeadingInset: CGFloat = 16
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8.fitH) {
                ForEach(HomeCategory.allCases, id: \.self) { item in
                    let isSelected = (selection == item)
                    
                    Text(item.rawValue)
                        .font(isSelected ? selectedFont : normalFont)
                        .foregroundStyle(isSelected ? .white : .gray707070)
                        .padding(.vertical, 10.fitH)
                        .padding(.leading, 16.fitW)
                        .padding(.trailing, 10.fitW)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selection = item
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Capsule()
                                    .matchedGeometryEffect(id: "underline", in: underlineNS)
                                    .frame(height: 2.fitH)
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }
            .padding(.horizontal, 16.fitW)
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .frame(height: 1.fitH)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, baseLineLeadingInset)
                    .foregroundStyle(.white.opacity(0.2))
                    .allowsHitTesting(false)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 6.fitW) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.grayB3B3B3)
            TextField(
                "",
                      text: $text,
                      prompt: Text("Search")
                .font(.manropeRegular(size: 16.fitW))
                .foregroundStyle(.grayB3B3B3)
            )
            .textInputAutocapitalization(.never)
            .foregroundStyle(.white)
            Button {
                print("SFX: Tap")
            } label: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.grayB3B3B3)
            }
        }
        .padding(12.fitH)
        .background(.gray2C2C2C.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16.fitW))
        .padding(.horizontal, 16.fitW)
    }
}


struct PlaylistCard: View {
    let cover: Image
    let title: String
    let subtitle: String
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .zero) {
                cover
                    .resizable().scaledToFill()
                    .frame(width: 152.fitW, height: 152.fitW)
                    .clipShape(RoundedRectangle(cornerRadius: 22.fitW))
                    .padding(.bottom, 8.fitH)

                Text(title)
                    .font(.manropeSemiBold(size: 14.fitW))
                    .foregroundStyle(.white)
                    .padding(.bottom, 2.fitH)

                Text(subtitle)
                    .font(.manropeRegular(size: 12.fitW))
                    .foregroundStyle(.gray707070)
            }
            .frame(width: 152.fitW, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 22.fitW))
        }
        .buttonStyle(.plain)
    }
}

struct TrendingRow: View {
    let rank: Int
    let cover: Image
    let title: String
    let artist: String
    var onMenuTap: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 8.fitW) {
            
            VStack(spacing: 6.fitH) {
                Text("\(rank)")
                    .font(.manropeSemiBold(size: 20.fitW))
                    .foregroundStyle(.white)
                
                Capsule()
                    .frame(width: 14.fitW, height: 3.fitH)
                    .foregroundStyle(.white)
            }
            .frame(width: 30.fitW, alignment: .center)
            
            cover
                .resizable()
                .scaledToFill()
                .frame(width: 64.fitW, height: 64.fitW)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2.fitH) {
                Text(title)
                    .font(.manropeSemiBold(size: 18.fitW))
                    .foregroundStyle(.white)
                
                Text(artist)
                    .font(.manropeRegular(size: 15.fitW))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.leading, 5.fitW)
            
            Spacer(minLength: 12)
            
            Button(action: onMenuTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18.fitW, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 2)
            }
            .buttonStyle(.plain)
            
        }
        .padding(.vertical, 8.fitH)
        .contentShape(Rectangle())
    }
}

#Preview {
    MainView()
        .environmentObject(Router())
}
