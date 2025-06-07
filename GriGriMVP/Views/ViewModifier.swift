//
//  ViewModifier.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import SwiftUI

//MARK: - Theme
struct AppTheme {
    static let appContentBG = Color("AppContentBackground")
    static let appBackgroundBG = Color("AppPageBackground")
    static let appPrimary = Color("AppAccentPrimary")
    static let appSecondary = Color("AppAccentSecondary")
    
    
    // Text Colors
    static let appTextPrimary = Color("TextPrimary")
    static let appTextLight = Color("TextLight")
    static let appTextAccent = Color("TextAccent")
    static let appTextButton = Color("TextButton")
    
}

// MARK: - Typography
extension Font {
    
   // Standard text styles
    static let appNavTitle = Font.system(size: 34, weight: .regular, design: .rounded)
    static let appHeadline = Font.system(size: 28, weight: .light, design: .rounded)
    static let appSubheadline = Font.system(size: 20, weight: .light, design: .rounded)
    static let appUnderline = Font.system(size: 15, weight: .light, design: .rounded)
    static let appButtonPrimary = Font.system(size: 20, weight: .regular, design: .rounded)
    static let appButtonSecondary = Font.system(size: 16, weight: .regular, design: .rounded)
    static let appProfileButton = Font.system(size: 13, weight: .regular, design: .rounded)
    static let appBody = Font.system(size: 13, weight: .light, design: .rounded)
}
