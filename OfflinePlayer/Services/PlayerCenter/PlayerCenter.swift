//
//  PlayerCenter.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 27.08.2025.
//

import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

struct NowPlayingMeta: Equatable {
    var title: String
    var artist: String
    var artworkURL: URL?
    var avatarURL: URL?
}

/// Элемент очереди плеера
struct PlayerQueueEntry: Identifiable, Equatable {
    var id: String
    var url: URL
    var meta: NowPlayingMeta
}

@MainActor
final class PlayerCenter: ObservableObject {
    static let shared = PlayerCenter()
    
    // MARK: Published (для SwiftUI)
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var buffered: Double = 0
    
    @Published private(set) var meta: NowPlayingMeta = .init(title: "", artist: "", artworkURL: nil)
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffleOn: Bool = false
    
    @Published private(set) var queue: [PlayerQueueEntry] = []
    @Published private(set) var currentIndex: Int = 0
    
    // MARK: Private
    private let player = AVPlayer()
    private var timeObs: Any?
    private var endObs: NSObjectProtocol?
    private var isScrubbing = false
    
    private init() {
        setupAudioSession()
        setupTimeObserver()
        setupEndObserver()
        setupRemoteCommands()
    }
    
    deinit {
        if let t = timeObs { player.removeTimeObserver(t) }
        if let e = endObs { NotificationCenter.default.removeObserver(e) }
    }
    
    // MARK: Bootstrap
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
        try? session.setActive(true)
    }
    
    private func setupTimeObserver() {
        timeObs = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
                                                 queue: .main) { [weak self] t in
            guard let self else { return }
            guard !isScrubbing else { return }
            
            let seconds = t.seconds
            self.currentTime = seconds.isFinite ? seconds : 0
            
            if let d = player.currentItem?.duration.seconds, d.isFinite {
                self.duration = d
            } else {
                self.duration = 0
            }
            
            if let r = player.currentItem?.loadedTimeRanges.first?.timeRangeValue {
                let end = CMTimeAdd(r.start, r.duration).seconds
                self.buffered = end
            } else {
                self.buffered = 0
            }
        }
    }
    
    private func setupEndObserver() {
        endObs = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.handleItemFinished() }
    }
    
    // MARK: Queue / Play
    func setQueue(_ entries: [PlayerQueueEntry], startAt index: Int = 0, autoplay: Bool = true) {
        queue = entries
        currentIndex = max(0, min(index, entries.count - 1))
        loadCurrentItem()
        if autoplay {
            play()
        }
    }
    
    func replaceWithSingle(_ entry: PlayerQueueEntry, autoplay: Bool = true) {
        setQueue([entry], startAt: 0, autoplay: autoplay)
    }
    
    private func loadCurrentItem() {
        guard queue.indices.contains(currentIndex) else { return }
        let e = queue[currentIndex]
        let item = AVPlayerItem(url: e.url)
        player.replaceCurrentItem(with: item)

        currentTime = 0
        duration = 0
        buffered = 0
        meta = e.meta
        
        updateNowPlayingInfo()
    }
    
    // MARK: Controls
    func play() {
        player.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }
    
    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }
    
    func togglePlay() {
        isPlaying ? pause() : play()
    }
    
    func seek(to seconds: Double) {
        let t = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = seconds
        updateNowPlayingElapsedTime()
    }
    
    func beginScrubbing() { isScrubbing = true }
    func endScrubbing(to seconds: Double) {
        isScrubbing = false
        seek(to: seconds)
    }
    
    func next() {
        guard !queue.isEmpty else { return }
        if isShuffleOn {
            currentIndex = Int.random(in: 0..<queue.count)
        } else {
            if currentIndex == queue.count - 1 {
                if repeatMode == .all {
                    currentIndex = 0
                } else {
                    pause()
                    seek(to: 0)
                    return
                }
            } else {
                currentIndex += 1
            }
        }
        loadCurrentItem()
        play()
    }
    
    func prev() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0); return
        }
        if isShuffleOn {
            currentIndex = Int.random(in: 0..<queue.count)
        } else if currentIndex == 0 {
            if repeatMode == .all {
                currentIndex = queue.count - 1
            } else {
                seek(to: 0); return
            }
        } else {
            currentIndex -= 1
        }
        loadCurrentItem()
        play()
    }
    
    private func handleItemFinished() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            play()
        case .off, .all:
            next()
        }
    }

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in self?.togglePlay(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.prev(); return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] ev in
            guard let self, let p = ev as? MPChangePlaybackPositionCommandEvent else { return .noSuchContent }
            self.seek(to: p.positionTime); return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        var info: [String : Any] = [
            MPMediaItemPropertyTitle: meta.title,
            MPMediaItemPropertyArtist: meta.artist,
        ]
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
  
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func updateNowPlayingPlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func updateNowPlayingElapsedTime() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

extension PlayerCenter {
    var currentEntry: PlayerQueueEntry? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }
    //Nureke
    func currentDurationSecondsAsync() async -> TimeInterval {
           guard let item = player.currentItem else { return 0 }
           if #available(iOS 16.0, *) {
               do {
                   let cm = try await item.asset.load(.duration)
                   return cm.isNumeric ? cm.seconds : 0
               } catch {
                   return 0
               }
           } else {
               let cm = item.asset.duration
               return cm.isNumeric ? cm.seconds : 0
           }
       }

    func currentTimeSeconds() -> TimeInterval {
            player.currentItem?.currentTime().seconds ?? 0
        }
}
