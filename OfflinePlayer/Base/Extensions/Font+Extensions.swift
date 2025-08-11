//
//  Font+Extensions.swift
//  DeepAI
//
//  Created by Roman Gorodilov on 15.04.2025.
//

import SwiftUI

extension Font {
    
    static func manropeBold(size: CGFloat) -> Font {
        Font.custom("Manrope-Bold.ttf", size: size)
    }

    static func manropeRegular(size: CGFloat) -> Font {
        Font.custom("Manrope-Regular.ttf", size: size)
    }
    
    static func manropeSemiBold(size: CGFloat) -> Font {
        Font.custom("Manrope-SemiBold.ttf", size: size)
    }
    
    static func manropeExtraBold(size: CGFloat) -> Font {
        Font.custom("Manrope-ExtraBold.ttf", size: size)
    }
}

extension UIFont {
    static func manropeRegularity(size: CGFloat) -> UIFont {
        return UIFont(name: "Manrope-Regular.ttf", size: size)!
    }
}
