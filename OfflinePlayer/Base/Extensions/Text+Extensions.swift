//
//  Text+Extensions.swift
//  WeatherPoetry
//
//  Created by Abylaikhan Abilkayr on 27.07.2025.
//

import SwiftUI

extension Text {
    func oneLineMinimumScale() -> some View {
        self.multipleLinesMinimumScale(1)
    }
    
    func multipleLinesMinimumScale(_ linesCount: Int) -> some View {
        self.lineLimit(linesCount).minimumScaleFactor(0.5)
    }
}
