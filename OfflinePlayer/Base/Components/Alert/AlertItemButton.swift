//
//  AlertItemButton.swift
//  WeatherPoetry
//
//  Created by Abylaikhan Abilkayr on 05.08.2025.
//

import SwiftUI

enum AlertItemButtonStyle {
    case destructive, `default`, cancel
}

struct AlertItemButton {
    
    // MARK: - Public Properties
    
    let titleText: String
    
    let style: AlertItemButtonStyle

    var action: () -> Void = {}

    // MARK: - Public Methods
    
    func toAlertButton() -> Alert.Button {
        switch style {
        case .default:
            .default(Text(titleText), action: action)
        case .cancel:
            .cancel(Text(titleText), action: action)
        case .destructive:
            .destructive(Text(titleText), action: action)
        }
    }
}
