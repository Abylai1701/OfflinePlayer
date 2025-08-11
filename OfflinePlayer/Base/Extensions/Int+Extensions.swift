//
//  Int+Extensions.swift
//  WeatherPoetry
//
//  Created by Abylaikhan Abilkayr on 27.07.2025.
//

import UIKit

extension Int {

    // MARK: - Public Properties
    
    /// Подогнать под ширину базового экрана.
    var fitW: CGFloat {
        let ratio = screenSize.width / baseiPhoneSize.width
        return CGFloat(self) * ratio
    }

    /// Подогнать под высоту базового экрана.
    var fitH: CGFloat {
        let ratio = screenSize.height / baseiPhoneSize.height
        return CGFloat(self) * ratio
    }
    
    // MARK: - Private Properties
    
    private var baseiPhoneSize: (width: CGFloat, height: CGFloat) { (375, 812) }
    private var screenSize: CGSize { UIScreen.main.bounds.size }
}
