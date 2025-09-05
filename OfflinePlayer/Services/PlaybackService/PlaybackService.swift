//
//  PlaybackService.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 01.09.2025.
//

import Foundation

@MainActor
final class PlaybackService: ObservableObject {
    static let shared = PlaybackService()
    
    private let host = AudiusHostProvider()
    private lazy var api = AudiusAPI(host: host, appName: "OfflineOlen", logLevel: .errors)
    
    //Nureke
    @Published private(set) var eqEnabled: Bool = false
    private(set) var eqBands: [EQBand] = []
    
    private init() {}
    
    /// Проиграть один трек (заменяет очередь)
    func play(_ t: MyTrack, autoplay: Bool = true) async {
        do {
            try await host.ensureHost()
            let url = try await api.streamURL(for: t.id)
            
            let entry = PlayerQueueEntry(
                id: t.id,
                url: url,
                meta: .init(title: t.title, artist: t.artist, artworkURL: t.artworkURL)
            )
            //            PlayerCenter.shared.replaceWithSingle(entry, autoplay: autoplay)
            //Nureke
            if eqEnabled {
                try await EqualizerService.shared.playRemote(url: url)
                PlayerCenter.shared.replaceWithSingle(entry, autoplay: false)
            } else {
                PlayerCenter.shared.replaceWithSingle(entry, autoplay: autoplay)
            }
        } catch {
            print("[PlaybackService] play error:", error.localizedDescription)
        }
    }
    
    /// Проиграть очередь из треков, стартуя с индекса
    func playQueue(_ tracks: [MyTrack], startAt index: Int = 0, autoplay: Bool = true) async {
        do {
            try await host.ensureHost()
            
            var entries: [PlayerQueueEntry] = []
            entries.reserveCapacity(tracks.count)
            
            for t in tracks {
                if let url = try? await api.streamURL(for: t.id) {
                    entries.append(PlayerQueueEntry(
                        id: t.id,
                        url: url,
                        meta: .init(title: t.title, artist: t.artist, artworkURL: t.artworkURL)
                    ))
                }
            }
            
            guard !entries.isEmpty else { return }
            let start = min(max(0, index), entries.count - 1)
            
            //PlayerCenter.shared.setQueue(entries, startAt: start, autoplay: autoplay)
            
            //Nureke
            if eqEnabled {
                PlayerCenter.shared.setQueue(entries, startAt: start, autoplay: false)
                try await EqualizerService.shared.playRemote(url: entries[start].url)
            } else {
                PlayerCenter.shared.setQueue(entries, startAt: start, autoplay: autoplay)
            }
        } catch {
            print("[PlaybackService] playQueue error:", error.localizedDescription)
        }
    }
    
    /// Добавить в конец текущей очереди и (опционально) начать играть, если ничего не играет
    func enqueue(_ t: MyTrack, autoplayIfIdle: Bool = true) async {
        do {
            try await host.ensureHost()
            let url = try await api.streamURL(for: t.id)
            let entry = PlayerQueueEntry(
                id: t.id,
                url: url,
                meta: .init(title: t.title, artist: t.artist, artworkURL: t.artworkURL)
            )
            var q = PlayerCenter.shared.queue
            q.append(entry)
            PlayerCenter.shared.setQueue(q, startAt: PlayerCenter.shared.currentIndex, autoplay: PlayerCenter.shared.isPlaying || autoplayIfIdle)
        } catch {
            print("[PlaybackService] enqueue error:", error.localizedDescription)
        }
    }
}

//MARK: - Nureke Extensions
extension PlaybackService {
    func streamURL(for track: MyTrack) async throws -> URL {
        try await api.streamURL(for: track.id)
    }
    
    func setEqualizer(isOn: Bool, bands: [EQBand], restartIfNeeded: Bool = false) {
        eqEnabled = isOn
        eqBands   = bands
        EqualizerService.shared.isEnabled = isOn
        EqualizerService.shared.apply(bands: bands)
        
        if restartIfNeeded, isOn {
            migrateFromAVPlayerToEnginePreservingPosition()
        }
    }
    
    private func migrateFromAVPlayerToEnginePreservingPosition() {
        guard let entry = PlayerCenter.shared.currentEntry else { return }
        // 1) текущее время из AVPlayer
        let currentSec = PlayerCenter.shared.currentTimeSeconds()
        // 2) ставим паузу, чтобы не было двойного звука
        PlayerCenter.shared.pause()
        // 3) запускаем движок с оффсетом
        Task {
            do { try await EqualizerService.shared.playRemote(url: entry.url, startAt: currentSec) }
            catch { print("EQ migrate error:", error.localizedDescription) }
        }
    }
    
    func togglePlay() {
        if eqEnabled {
            if EqualizerService.shared.isPlaying {
                EqualizerService.shared.pause()
                return
            }
            if EqualizerService.shared.hasLoadedTrack {
                EqualizerService.shared.resume()
                return
            }
            if let entry = PlayerCenter.shared.currentEntry {
                let t = PlayerCenter.shared.currentTimeSeconds()
                Task {
                    try? await EqualizerService.shared.playRemote(url: entry.url, startAt: t)
                }
            }
            return
        }
        PlayerCenter.shared.togglePlay()
    }
    
    func pause() {
        if eqEnabled { EqualizerService.shared.pause() }
        PlayerCenter.shared.pause()
    }
    
    func stopPlayback() {
        if eqEnabled { EqualizerService.shared.stop() }
        PlayerCenter.shared.pause()
    }
    
}
