//
//  ClimbingTypePill.swift
//  GriGriMVP
//
//  Created by Sam Quested on 10/11/2025.
//

import SwiftUI

/// A pill-shaped component that displays a climbing type with its corresponding icon
/// Styled to match the outline primary action button style
struct ClimbingTypePill: View {
    let climbingType: ClimbingTypes
    let size: PillSize

    init(climbingType: ClimbingTypes, size: PillSize = .medium) {
        self.climbingType = climbingType
        self.size = size
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            ClimbingTypeIcons.icon(for: climbingType)
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)
                .offset(x: -2)

            Text(climbingType.displayName)
                .font(size.font)
                .foregroundColor(AppTheme.appPrimary)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(AppTheme.appPrimary, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .shadow(color: AppTheme.appPrimary.opacity(0.3), radius: size.shadowRadius, x: 0, y: 2)
    }

    enum PillSize {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 26
            case .medium: return 30
            case .large: return 35
            }
        }

        var font: Font {
            switch self {
            case .small: return .system(size: 13, weight: .medium, design: .rounded)
            case .medium: return .system(size: 15, weight: .medium, design: .rounded)
            case .large: return .system(size: 18, weight: .semibold, design: .rounded)
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 16
            case .large: return 24
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 10
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 18
            case .medium: return 20
            case .large: return 26
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 0
            case .medium: return 4
            case .large: return 6
            }
        }
    }
}

// MARK: - ClimbingTypeIcons Helper
struct ClimbingTypeIcons {
    static func icon(for type: ClimbingTypes) -> Image {
        switch type {
        case .bouldering:
            return AppIcons.boulder
        case .sport:
            return AppIcons.sport
        case .board:
            return AppIcons.board
        case .gym:
            return AppIcons.gym
        }
    }
}

// MARK: - ClimbingTypes Extension
extension ClimbingTypes {
    var displayName: String {
        switch self {
        case .bouldering:
            return "Bouldering"
        case .sport:
            return "Sport"
        case .board:
            return "Board"
        case .gym:
            return "Gym"
        }
    }
}

#Preview("All Climbing Types - Medium") {
    VStack(spacing: 12) {
        ForEach(ClimbingTypes.allCases, id: \.self) { climbingType in
            ClimbingTypePill(climbingType: climbingType, size: .medium)
        }
    }
    .padding()
}

#Preview("Size Variations - Bouldering") {
    VStack(spacing: 12) {
        ClimbingTypePill(climbingType: .bouldering, size: .small)
        ClimbingTypePill(climbingType: .bouldering, size: .medium)
        ClimbingTypePill(climbingType: .bouldering, size: .large)
    }
    .padding()
}

#Preview("All Climbing Types - All Sizes") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Small")
                    .font(.headline)
                ForEach(ClimbingTypes.allCases, id: \.self) { climbingType in
                    ClimbingTypePill(climbingType: climbingType, size: .small)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Medium")
                    .font(.headline)
                ForEach(ClimbingTypes.allCases, id: \.self) { climbingType in
                    ClimbingTypePill(climbingType: climbingType, size: .medium)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Large")
                    .font(.headline)
                ForEach(ClimbingTypes.allCases, id: \.self) { climbingType in
                    ClimbingTypePill(climbingType: climbingType, size: .large)
                }
            }
        }
        .padding()
    }
}