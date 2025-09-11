//
//  EQModels.swift
//  OfflinePlayer
//
//  Created by Abylaikhan Abilkayr on 12.09.2025.
//

import Foundation

struct EQBand: Identifiable {
    let id = UUID()
    let label: String
    let gain: Double
}

extension EQBand {
    var freq: Double {
        switch label {
        case "60 Hz": return 60
        case "150 Hz": return 150
        case "400 Hz": return 400
        case "1.0 kHz": return 1000
        case "2.4 kHz": return 2400
        case "15 kHz": return 15000
        default: return 1000
        }
    }
    
    var setting: EQBandSetting {
        EQBandSetting(freq: freq, gainDB: gain, q: 1.0)
    }
}

struct EQPreset: Identifiable {
    let id = UUID()
    let name: String
    let bands: [EQBand]
}
