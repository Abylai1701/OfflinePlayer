//
//  Track.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 14.08.2025.
//
import SwiftUI

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let cover: Image
}
