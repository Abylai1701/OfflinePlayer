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
            PlayerCenter.shared.replaceWithSingle(entry, autoplay: autoplay)
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
            PlayerCenter.shared.setQueue(entries, startAt: start, autoplay: autoplay)
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
