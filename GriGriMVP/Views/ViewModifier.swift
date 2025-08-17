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
    static let appCardTitleLarge = Font.system(size: 20, weight: .light, design: .rounded)
    static let appCardTitleSmall = Font.system(size: 18, weight: .light, design: .rounded)
    static let appUnderline = Font.system(size: 15, weight: .light, design: .rounded)
    static let appButtonPrimary = Font.system(size: 20, weight: .regular, design: .rounded)
    static let appButtonSecondary = Font.system(size: 16, weight: .regular, design: .rounded)
    static let appProfileButton = Font.system(size: 13, weight: .regular, design: .rounded)
    static let appBody = Font.system(size: 13, weight: .light, design: .rounded)
}

// MARK: - Icons

struct AppIcons {
    
    static let boulder = Image("Boulder")
    static let sport = Image("Sport")
    static let board = Image("Board")
    static let gym = Image("Gym")
}

struct AmmenitiesIcons {
    static let showers = Image(systemName: "shower.fill")
    static let lockers = Image(systemName: "lock.fill")
    static let bar = Image(systemName: "wineglass.fill")
    static let food = Image(systemName: "fork.knife")
    static let changingRooms = Image(systemName: "door.right.hand.closed")
    static let bathrooms = Image(systemName: "sink.fill")
    static let cafe = Image(systemName: "cup.and.saucer.fill")
    static let bikeStorage = Image(systemName: "bicycle")
    static let workSpace = Image(systemName: "desktopcomputer")
    static let shop = Image(systemName: "storefront.fill")
    static let wifi = Image(systemName: "wifi")
    
    // Method to get icon for amenity
    static func icon(for amenity: Amenities) -> Image {
        switch amenity {
        case .showers:
            return showers
        case .lockers:
            return lockers
        case .bar:
            return bar
        case .food:
            return food
        case .changingRooms:
            return changingRooms
        case .bathrooms:
            return bathrooms
        case .cafe:
            return cafe
        case .bikeStorage:
            return bikeStorage
        case .workSpace:
            return workSpace
        case .shop:
            return shop
        case .wifi:
            return wifi
        }
    }
}
