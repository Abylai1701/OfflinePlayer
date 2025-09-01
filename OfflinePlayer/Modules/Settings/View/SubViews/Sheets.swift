//
//  Sheets.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 22.08.2025.
//
import SwiftUI

struct RateUsSheet: View {
    var body: some View {
        SheetScaffold(title: "Rate Us") {
            Text("Ask the user to rate the app or deep-link to the App Store.")
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 8)
        }
    }
}

struct ShareWithFriendsSheet: View {
    var body: some View {
        SheetScaffold(title: "Share with Friends") {
            Text("Opened FriendSheet.")
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 8)
        }
    }
}

struct LegalSheet: View {
    let title: String
    var body: some View {
        SheetScaffold(title: title) {
            Text("Place to legal text or WebView/SafariView here.")
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 8)
        }
    }
}

struct FeedbackSheet: View {
    @State private var text = ""
    var body: some View {
        SheetScaffold(title: "Share Feedback") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tell us what you think:")
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Button {
                    //
                } label: {
                    Text("Send")
                        .font(.manropeRegular(size: 16))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .foregroundStyle(.white)
        }
    }
}
