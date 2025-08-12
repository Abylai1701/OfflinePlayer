//
//  TrendingNowView.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 12.08.2025.
//
import SwiftUI

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let cover: Image
}

struct TrendingNowView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = TrendingNowViewModel()
    
    @State private var search: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16.fitH) {
                
                // Header
                HStack(spacing: 12.fitW) {
                    Button {
                        viewModel.back()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18.fitW, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 14.fitW, height: 28.fitH)
                            .contentShape(Rectangle())
                    }
                    
                    Text("Trending Now")
                        .font(.manropeExtraBold(size: 24.fitH))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.top, 16.fitH)
                .padding(.horizontal, 16.fitW)
                
                // Search
                SearchBar(text: $search)
                    .padding(.horizontal, 16.fitW)
                
                // List
                LazyVStack(spacing: 0) {
                    ForEach(1...20, id: \.self) { rank in
                        TrendingRow(
                            rank: rank,
                            cover: Image(.image),      // поставь свой ассет
                            title: sampleTitles[rank % sampleTitles.count],
                            artist: sampleArtists[rank % sampleArtists.count]
                        )
                        .padding(.horizontal, 16.fitW)
                    }
                }
                .padding(.bottom, 24.fitH)
            }
        }
        .task {
            viewModel.attach(router: router)
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// Mock примеры данных
private let sampleTitles  = ["Lost in Static", "Dreamy Skies", "No Sleep City",
                             "Fireproof Heart", "Mirror Maze", "Midnight Carousel",
                             "Runaway Signal", "Hello"]
private let sampleArtists = ["Kai Verne", "Luma Rae", "Drex Malone",
                             "Novaa", "Arlo Mav", "The Amber Skies",
                             "KERO & Flashline", "—"]
#Preview {
    TrendingNowView()
}
