//
//  Font+Extensions.swift
//  DeepAI
//
//  Created by Roman Gorodilov on 15.04.2025.
//

import SwiftUI

extension Font {
    
    static func manropeBold(size: CGFloat) -> Font {
        .custom("Manrope-Bold", size: size)
    }

    static func manropeRegular(size: CGFloat) -> Font {
        .custom("Manrope-Regular", size: size)
    }
    
    static func manropeMedium(size: CGFloat) -> Font {
        .custom("Manrope-Medium", size: size)
    }
    
    static func manropeSemiBold(size: CGFloat) -> Font {
        .custom("Manrope-SemiBold", size: size)
    }
    
    static func manropeExtraBold(size: CGFloat) -> Font {
        .custom("Manrope-ExtraBold", size: size)
    }
}

extension UIFont {
    static func manropeRegularity(size: CGFloat) -> UIFont {
        return UIFont(name: "Manrope-Regular.ttf", size: size)!
    }
}
