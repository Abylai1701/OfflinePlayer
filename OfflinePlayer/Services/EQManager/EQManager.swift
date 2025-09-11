//
//  EQManager.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 10.09.2025.
//

import Foundation
import Combine

struct EQBandSetting: Identifiable, Equatable {
    let id = UUID()
    let freq: Double       // Гц
    var gainDB: Double     // -12 ... +12
    var q: Double          // добротность (ширина)
}

@MainActor
final class EqualizerManager: ObservableObject {
    static let shared = EqualizerManager()
    private init() {}

    /// Вкл/выкл эквалайзер
    @Published var isOn: Bool = false {
        didSet { notifyChanged() }
    }

    /// 6 полос (частоты те, что у тебя в UI)
    @Published var bands: [EQBandSetting] = [
        .init(freq:  60,    gainDB: 0, q: 0.9),  // low-shelf
        .init(freq: 150,    gainDB: 0, q: 1.0),
        .init(freq: 400,    gainDB: 0, q: 1.0),
        .init(freq: 1000,   gainDB: 0, q: 1.0),
        .init(freq: 2400,   gainDB: 0, q: 1.0),
        .init(freq: 15000,  gainDB: 0, q: 0.8),  // high-shelf
    ] {
        didSet { notifyChanged() }
    }

    /// Пресеты (пример — подставь свои)
    let presets: [EQPreset] = [
        EQPreset(name: "Default", bands: [
            .init(label: "60 Hz",   gain: 0),
            .init(label: "150 Hz",  gain: 0),
            .init(label: "400 Hz",  gain: 0),
            .init(label: "1.0 kHz", gain: 0),
            .init(label: "2.4 kHz", gain: 0),
            .init(label: "15 kHz",  gain: 0),
        ]),
        // ... твои остальные
    ]

    /// Вызывается при любом изменении настроек
    var onDidChange: (() -> Void)?

    func applyPreset(_ p: EQPreset) {
        let freqs = [60.0, 150.0, 400.0, 1000.0, 2400.0, 15000.0]
        var newBands: [EQBandSetting] = []
        for (i, b) in p.bands.enumerated() {
            let f = freqs[min(i, freqs.count-1)]
            let q = (i == 0 ? 0.9 : (i == freqs.count-1 ? 0.8 : 1.0))
            newBands.append(.init(freq: f, gainDB: b.gain, q: q))
        }
        bands = newBands
    }

    func setBands(_ newBands: [EQBandSetting]) {
        bands = newBands
    }
    
    private func notifyChanged() { onDidChange?() }
}
