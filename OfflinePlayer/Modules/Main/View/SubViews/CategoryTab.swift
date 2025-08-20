//
//  CategoryTab.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 20.08.2025.
//

import SwiftUI

enum HomeCategory: String, CaseIterable, Hashable {
    case popular = "Popular", new = "New", trend = "Trend", favorites = "Favorites", relax = "Relax", sport = "Sport"
}

struct CategoryTabs: View {
    @Binding var selection: HomeCategory
    @Namespace private var underlineNS
    
    var selectedFont: Font = .manropeMedium(size: 14.fitW)
    var normalFont: Font = .manropeRegular(size: 14.fitW)
    
    private let baseLineLeadingInset: CGFloat = 16
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .zero) {
                ForEach(HomeCategory.allCases, id: \.self) { item in
                    let isSelected = (selection == item)
                    
                    Text(item.rawValue)
                        .font(isSelected ? selectedFont : normalFont)
                        .foregroundStyle(isSelected ? .white : .gray707070)
                        .padding(.vertical, 10.fitH)
                        .padding(.horizontal, 16.fitW)
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
                    .foregroundStyle(.gray707070)
                    .allowsHitTesting(false)
            }
        }
    }
}
