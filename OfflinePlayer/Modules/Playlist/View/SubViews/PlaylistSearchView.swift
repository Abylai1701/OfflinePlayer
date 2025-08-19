//
//  PlaylistSearchView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 18.08.2025.
//

import SwiftUI

struct PlaylistSearchView: View {
    
    @State var searchText: String = ""
    
    var body: some View {
        SearchBar(text: $searchText, type: .playlist)
    }
}

#Preview {
    PlaylistSearchView()
}
