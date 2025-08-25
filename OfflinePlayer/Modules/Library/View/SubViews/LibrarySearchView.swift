//
//  Untitled.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 19.08.2025.
//

import SwiftUI

struct LibrarySearchView: View {
    
    @Binding var searchText: String

    var body: some View {
        SearchBar(text: $searchText, type: .library)
    }
}
