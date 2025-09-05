//
//  SearchBar.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 18.08.2025.
//

import SwiftUI

struct SearchBar: View {
    
    enum SearchBarType {
        case home
        case playlist
        case library
    }
    
    @Binding var text: String
    var type: SearchBarType = .home
    var isRecording: Bool = false
    var onMicTap: (() -> Void)? = nil
    
    private var placeholder: String {
        switch type {
        case .home:
            return "Search"
        case .playlist:
            return "Favorite tracks & Singers"
        case .library:
            return "Search by tracks"
        }
    }
    
    var body: some View {
        HStack(spacing: 6.fitW) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.grayB3B3B3)
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .font(.manropeRegular(size: 16.fitW))
                    .foregroundStyle(.grayB3B3B3)
            )
            .textInputAutocapitalization(.never)
            .foregroundStyle(.white)
            Button {
                onMicTap?()
            }
            label: {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .symbolEffect(.pulse, isActive: isRecording)
                    .foregroundStyle(.grayB3B3B3)
            }
        }
        .padding(12.fitH)
        .background(.gray2C2C2C.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16.fitW))
        .padding(.horizontal, 16.fitW)
    }
}
