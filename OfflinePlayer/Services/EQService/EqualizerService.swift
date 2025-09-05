//
//  EqualizerService.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 05.09.2025.
//


import Foundation
import AVFoundation

final class EqualizerService: ObservableObject {
    static let shared = EqualizerService()
    private init() { setupGraph() }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: 6)

    @Published private(set) var isPlaying: Bool = false
    @Published var isEnabled: Bool = true {
        didSet { eq.bypass = !isEnabled }
    }
    
    private var file: AVAudioFile?
    private var startFrame: AVAudioFramePosition = 0
    private var sampleRate: Double = 44100
    private var totalFrames: AVAudioFramePosition = 0
    
    var currentTimeSeconds: TimeInterval {
            guard let nodeTime = player.lastRenderTime,
                  let p = player.playerTime(forNodeTime: nodeTime) else { return 0 }
            let played = AVAudioFramePosition(p.sampleTime)
            return Double(startFrame + played) / sampleRate
        }
        var durationSeconds: TimeInterval {
            guard totalFrames > 0 else { return 0 }
            return Double(totalFrames) / sampleRate
        }
    
    var hasLoadedTrack: Bool {
        file != nil && totalFrames > 0
    }

    private func ensurePlaybackSession() throws {
            let s = AVAudioSession.sharedInstance()

            try s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try s.setActive(true, options: .notifyOthersOnDeactivation)
        }

    private func setupGraph() {
        let freqs: [Float] = [60, 150, 400, 1000, 2400, 15000]
        let types: [AVAudioUnitEQFilterType] = [.lowShelf, .parametric, .parametric, .parametric, .parametric, .highShelf]
        let bws:   [Float] = [0.0, 0.9, 0.9, 0.8, 0.8, 0.0]

        for i in 0..<eq.bands.count {
            let b = eq.bands[i]
            b.filterType = types[i]
            b.frequency  = freqs[i]
            b.bandwidth  = bws[i]
            b.gain       = 0
            b.bypass     = false
        }
        engine.attach(player)
        engine.attach(eq)
        engine.connect(player, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    func apply(bands: [EQBand]) {
        let n = min(bands.count, eq.bands.count)
        for i in 0..<n {
            eq.bands[i].gain = Float(bands[i].gain)
        }
    }

    func setBand(_ index: Int, gainDB: Float) {
        guard (0..<eq.bands.count).contains(index) else { return }
        eq.bands[index].gain = gainDB
    }

    func playLocal(url: URL, startAt: TimeInterval = 0) throws {
            player.stop()

            let f = try AVAudioFile(forReading: url)
            file = f
            sampleRate  = f.processingFormat.sampleRate
            totalFrames = f.length

            var desired = max(0, min(startAt, durationSeconds))
            startFrame  = AVAudioFramePosition(desired * sampleRate)
            var framesLeft = AVAudioFrameCount(max(0, totalFrames - startFrame))

            if framesLeft == 0, totalFrames > 0 {
                let tail = AVAudioFrameCount(
                    max(0, min(AVAudioFramePosition(sampleRate * 0.05), totalFrames))
                )
                startFrame = max(0, totalFrames - AVAudioFramePosition(tail))
                framesLeft = tail
                desired    = Double(startFrame) / sampleRate
            }

            player.scheduleSegment(
                f,
                startingFrame: startFrame,
                frameCount: framesLeft,
                at: nil
            ) { [weak self] in
                Task { @MainActor in self?.isPlaying = false }
            }

            try ensurePlaybackSession()
            if !engine.isRunning { try engine.start() }
            player.play()
            isPlaying = true
        }
    
    @MainActor
    func playRemote(url: URL, startAt: TimeInterval = 0) async throws {
        player.stop()

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 120
        cfg.waitsForConnectivity = false
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        let session = URLSession(configuration: cfg)

        func moveToOwnTmp(_ origin: URL, ext: String) throws -> URL {
            let ext = ext.isEmpty ? "mp3" : ext
            let dst = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            try? FileManager.default.removeItem(at: dst)
            try FileManager.default.moveItem(at: origin, to: dst)
            return dst
        }

        do {
            let (tmpURL, resp) = try await session.download(from: url)
            guard let http = resp as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let dst = try moveToOwnTmp(tmpURL, ext: url.pathExtension)
            try playLocal(url: dst, startAt: startAt)
            return
        } catch let e as URLError {
            print("[EQ] download() failed: \(e.code.rawValue) \(e)")
        } catch {
            print("[EQ] download() failed: \(error)")
        }

        do {
            let (data, resp) = try await session.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension
            let dst = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            try data.write(to: dst, options: .atomic)

            try playLocal(url: dst, startAt: startAt)
        } catch {
            print("[EQ] data() fallback failed: \(error)")
            throw error
        }
    }

    func pause() {
        player.pause()
        isPlaying = false
    }
    func resume() {
        if !engine.isRunning {
            try? engine.start()
        }
        player.play()
        isPlaying = true
    }
    func stop() {
        player.stop()
        isPlaying = false
    }
}
