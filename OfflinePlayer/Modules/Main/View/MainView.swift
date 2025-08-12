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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20.fitH) {

                Text("Home")
                    .font(.manropeExtraBold(size: 24.fitW))
                    .padding(.top)
                    .padding(.horizontal)
                    .foregroundStyle(.white)

                SearchBar(text: $search)
                    .padding(.horizontal)

                CategoryTabs(selection: $category)

                // Лента карточек (под категории можно подменять данные switch-case’ом)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16.fitH) {
                        ForEach(0..<5) { i in
                            PlaylistCard(
                                cover: Image(.image),   // твой ассет
                                title: "Playlist \(i+1)",
                                subtitle: "SZA, Rhye, Mac Miller"
                            )
                        }
                    }
                    .padding(.horizontal)
                    .contentMargins(.horizontal, 16.fitW, for: .scrollContent) // красивый отступ по краям
                }

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
                .padding(.top, 16.fitH)

                LazyVStack(spacing: 0) {
                    ForEach(1...10, id: \.self) { rank in
                        TrendingRow(rank: rank,
                                    cover: Image(.image),
                                    title: "Track \(rank)",
                                    artist: "Artist \(rank)")
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24.fitH)
            }
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(colors: [.gray222222, .black111111],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
        .task{
            viewModel.attach(router: router)
        }
        .navigationBarHidden(true)
    }
}

enum HomeCategory: String, CaseIterable, Hashable {
    case popular = "Popular", new = "New", trend = "Trend", favorites = "Favorites", relax = "Relax"
}

struct CategoryTabs: View {
    @Binding var selection: HomeCategory
    @Namespace private var underlineNS

    var selectedFont: Font = .manropeSemiBold(size: 16.fitW)
    var normalFont:   Font = .manropeRegular(size: 16.fitW)
    
    // сколько отступить базовой линии слева
    private let baseLineLeadingInset: CGFloat = 12

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24.fitH) {
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
            // Базовая линия с отступом слева
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
        HStack(spacing: 10.fitW) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray707070)
            TextField("",
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
                    .foregroundStyle(.gray707070)
            }
        }
        .padding(12)
        .background(
            .gray2C2C2C.opacity(0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}


struct PlaylistCard: View {
    let cover: Image
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8.fitH) {
            cover
                .resizable().scaledToFill()
                .frame(width: 152.fitW, height: 152.fitH)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            Text(title)
                .font(.manropeSemiBold(size: 14.fitW))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.manropeRegular(size: 12.fitW))
                .foregroundStyle(.gray707070)
        }
        .frame(width: 152.fitW)
    }
}


struct TrendingRow: View {
    let rank: Int
    let cover: Image
    let title: String
    let artist: String

    var body: some View {
        HStack(spacing: 8.fitW) {

            // Колонка с номером и короткой линией под ним
            VStack(spacing: 6.fitH) {
                Text("\(rank)")
                    .font(.manropeSemiBold(size: 20.fitW))
                    .foregroundStyle(.white)

                Capsule()
                    .frame(width: 14.fitW, height: 3.fitH)
                    .foregroundStyle(.white)
            }
            .frame(width: 30.fitW, alignment: .center)

            // Обложка
            cover
                .resizable()
                .scaledToFill()
                .frame(width: 64.fitW, height: 64.fitH)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Текст
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

            Image(systemName: "ellipsis")
                .font(.system(size: 18.fitW, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 2.fitW)
        }
        .padding(.vertical, 8.fitH)
        .contentShape(Rectangle()) // чтобы вся строка нажималась
    }
}

#Preview {
    MainView()
}
