//
//  EventFunctions.swift
//  OfflinePlayer
//
//  Created by Nurlybaqyt Begaly on 20.08.2025.
//

import SwiftUI

enum RepeatMode { case off, one, all }

enum FlashEvent: Equatable {
    case likeOn, likeOff
    case shuffleOn, shaffleOff
    case repeatOne, repeatOff
}
