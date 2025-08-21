//
//  SearchTabsView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 21.08.2025.
//

import SwiftUI

enum SearchScope: String, CaseIterable {
    case all = "All", top = "Top", tracks = "Tracks", singer = "Singer", album = "Album", playlists = "Playlists"
}

struct SearchTabs: View {
    @Binding var selection: SearchScope
    @Namespace private var ns

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .zero) {
                ForEach(SearchScope.allCases, id: \.self) { s in
                    let selected = (selection == s)
                    Text(s.rawValue)
                        .font(selected ? .manropeMedium(size: 14.fitW) : .manropeRegular(size: 14.fitW))
                        .foregroundStyle(selected ? .white : .gray707070)
                        .padding(.vertical, 10.fitH)
                        .padding(.horizontal, 16.fitW)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selection = s
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if selected {
                                Capsule().matchedGeometryEffect(id: "underline_search", in: ns)
                                    .frame(height: 2.fitH)
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }
            .padding(.horizontal, 16.fitW)
        }
    }
}
