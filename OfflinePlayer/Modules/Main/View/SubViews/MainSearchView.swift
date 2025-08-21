//
//  MainSearchView.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 18.08.2025.
//

import SwiftUI

struct MainSearchView: View {
    
    @Binding var searchText: String
    var body: some View {
        SearchBar(text: $searchText)
    }
}
