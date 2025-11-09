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
    
    // Shadow
    static let appCardShadow = Color.black.opacity(0.1)
}

// MARK: - Spacing Design System
extension AppTheme {
    /// Consistent spacing values for a cohesive UI experience
    struct Spacing {
        // Base spacing unit (4pt grid system)
        static let baseUnit: CGFloat = 4
        
        // Standard spacing scales
        static let xs: CGFloat = 4      // 1 unit - minimal spacing
        static let small: CGFloat = 8   // 2 units - tight spacing
        static let medium: CGFloat = 12 // 3 units - standard spacing
        static let large: CGFloat = 16  // 4 units - section spacing
        static let xl: CGFloat = 20     // 5 units - prominent spacing
        static let xxl: CGFloat = 24    // 6 units - major section spacing
        static let xxxl: CGFloat = 32   // 8 units - screen-level spacing
        
        // Card-specific spacing
        static let cardPadding: CGFloat = medium        // 12pt padding inside cards
        static let cardSpacing: CGFloat = medium        // 12pt spacing between cards
        static let cardHorizontalPadding: CGFloat = medium // 12pt horizontal padding for card containers
        
        // Section-specific spacing
        static let sectionSpacing: CGFloat = xxl        // 24pt spacing between major sections
        static let sectionTitleSpacing: CGFloat = large // 16pt spacing after section titles
        static let sectionContentSpacing: CGFloat = small // 8pt spacing within section content
        
        // Screen-level spacing
        static let screenPadding: CGFloat = large       // 16pt default screen padding
        static let screenTopSpacing: CGFloat = xxl      // 24pt top spacing for first elements
    }
}

// MARK: - Typography
extension Font {
    
   // Standard text styles
    static let appNavTitle = Font.system(size: 34, weight: .regular, design: .rounded)
    static let appHeadline = Font.system(size: 28, weight: .light, design: .rounded)
    static let appSubheadline = Font.system(size: 20, weight: .light, design: .rounded)
    static let appEventHost = Font.system(size: 20, weight: .regular, design: .rounded)
    static let appCardTitleLarge = Font.system(size: 20, weight: .light, design: .rounded)
    static let appCardTitleSmall = Font.system(size: 18, weight: .light, design: .rounded)
    static let appUnderline = Font.system(size: 15, weight: .light, design: .rounded)
    static let appButtonPrimary = Font.system(size: 20, weight: .regular, design: .rounded)
    static let appButtonSecondary = Font.system(size: 16, weight: .regular, design: .rounded)
    static let appProfileButton = Font.system(size: 13, weight: .regular, design: .rounded)
    static let appBody = Font.system(size: 13, weight: .light, design: .rounded)
    static let appCaption = Font.system(size: 12, weight: .light, design: .rounded)
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

struct EventTypeIcons {
    static let competition = Image("Comp")
    static let social = Image("Social")
    static let openDay = Image("OpenDay")
    static let settingTaster = Image("Taster")
    static let opening = Image("Demo")
    static let gymClass = Image("Class")

    // Method to get icon for event type
    static func icon(for eventType: EventType) -> Image {
        switch eventType {
        case .competition:
            return competition
        case .social:
            return social
        case .openDay:
            return openDay
        case .settingTaster:
            return settingTaster
        case .opening:
            return opening
        case .gymClass:
            return gymClass
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.6), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .mask(content)
            .onAppear {
                phase = 1
            }
    }
}

// MARK: - View Extensions
extension View {
    func appCardShadow() -> some View {
        self.shadow(color: AppTheme.appCardShadow, radius: 4, x: 0, y: 4)
    }

    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
