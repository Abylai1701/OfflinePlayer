//
//  MiniPlayerBarRemote.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 03.09.2025.
//
import SwiftUI
import Kingfisher

struct MiniPlayerBarRemote: View {
    let coverURL: URL?
    let title: String
    let subtitle: String
    var onExpand: () -> Void = {}
    var onPlay: () -> Void = {}
    var onPause: () -> Void = {}
    
    @EnvironmentObject private var kb: KeyboardState
    @ObservedObject var playback = PlaybackService.shared
    @ObservedObject var engine   = EqualizerService.shared
    @ObservedObject var player   = PlayerCenter.shared
    @State private var duration: TimeInterval = 0
    
    var current: TimeInterval {
        playback.eqEnabled ? engine.currentTimeSeconds : player.currentTimeSeconds()
    }
    
    private var total: TimeInterval {
        playback.eqEnabled ? engine.durationSeconds : duration
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12.fitW) {
                Button(action: onExpand) {
                    HStack(spacing: 12.fitW) {
                        KFImage(coverURL)
                            .placeholder { Color.gray.opacity(0.2) }
                            .cacheOriginalImage()
                            .loadDiskFileSynchronously()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44.fitW, height: 44.fitW)
                            .clipShape(RoundedRectangle(cornerRadius: 10.fitW))
                        
                        VStack(alignment: .leading, spacing: 2.fitH) {
                            Text(title)
                                .font(.manropeSemiBold(size: 16.fitW))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(subtitle)
                                .font(.manropeRegular(size: 13.fitW))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 14.fitW) {
                    Button(action: onPause) {
                        Image("playlistPauseIcon")
                            .frame(width: 32.fitW, height: 32.fitW)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onPlay) {
                        Image("NextIcon")
                            .frame(width: 32.fitW, height: 32.fitW)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 12.fitH)
            
            Rectangle()
                .fill(Color.blue.opacity(0.9))
                .frame(height: max(2 / UIScreen.main.scale, 1))
        }
        .background(.black191919)
        .padding(.horizontal, 8.fitW)
        .padding(.bottom, kb.visible ? 0 : 50.fitH)
        .task(id: player.currentEntry?.id) {    
            if !playback.eqEnabled {
                duration = await player.currentDurationSecondsAsync()
            } else {
                duration = engine.durationSeconds
            }
        }
        .onChange(of: playback.eqEnabled) { _, isOn in
            Task {
                duration = isOn ? engine.durationSeconds
                : await player.currentDurationSecondsAsync()
            }
        }
    }
}
