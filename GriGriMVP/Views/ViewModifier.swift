//
//  ViewModifier.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import SwiftUI

//MARK: - Theme
struct AppTheme {
    static let appContent = Color("AppContent")
    static let appBackground = Color("AppBackground")
    static let appAccent = Color("AppAccent")
    
    
    // Text Colors
    static let appTextPrimary = Color("TextPrimary")
    static let appTextLight = Color("TextLight")
    static let appTextAccent = Color("TextAccent")
    static let appTextButton = Color("TextButton")
    
}

// MARK: - Typography
extension Font {
    
   // Standard text styles
    static let appTitle = Font.system(size: 34, weight: .regular, design: .rounded)
    static let appHeadline = Font.system(size: 28, weight: .light, design: .rounded)
    static let appSubheadline = Font.system(size: 13, weight: .light, design: .rounded)
    static let appBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let appButton = Font.system(size: 18, weight: .light, design: .rounded)
    static let appCaption = Font.system(size: 11, weight: .light, design: .rounded)
}
