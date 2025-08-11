//
//  UIApplication+Extensions.swift
//  WeatherPoetry
//
//  Created by Abylaikhan Abilkayr on 27.07.2025.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }?
            .endEditing(force)
    }
}
