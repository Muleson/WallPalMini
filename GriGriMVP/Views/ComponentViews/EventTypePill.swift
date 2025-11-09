//
//  EventTypePill.swift
//  GriGriMVP
//
//  Created by Sam Quested on 07/11/2025.
//

import SwiftUI

/// A pill-shaped component that displays an event type with its corresponding icon
/// Styled to match the outline primary action button style
struct EventTypePill: View {
    let eventType: EventType
    let size: PillSize

    init(eventType: EventType, size: PillSize = .medium) {
        self.eventType = eventType
        self.size = size
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            EventTypeIcons.icon(for: eventType)
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)

            Text(eventType.displayName)
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
            case .small: return 24.5  // 14 * 1.75
            case .medium: return 28   // 16 * 1.75
            case .large: return 35    // 20 * 1.75
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
            case .small: return 8
            case .medium: return 16
            case .large: return 24
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 24
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
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
}

#Preview("All Event Types - Medium") {
    VStack(spacing: 12) {
        ForEach(EventType.allCases, id: \.self) { eventType in
            EventTypePill(eventType: eventType, size: .medium)
        }
    }
    .padding()
}

#Preview("Size Variations - Competition") {
    VStack(spacing: 12) {
        EventTypePill(eventType: .competition, size: .small)
        EventTypePill(eventType: .competition, size: .medium)
        EventTypePill(eventType: .competition, size: .large)
    }
    .padding()
}

#Preview("All Event Types - All Sizes") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Small")
                    .font(.headline)
                ForEach(EventType.allCases, id: \.self) { eventType in
                    EventTypePill(eventType: eventType, size: .small)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Medium")
                    .font(.headline)
                ForEach(EventType.allCases, id: \.self) { eventType in
                    EventTypePill(eventType: eventType, size: .medium)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Large")
                    .font(.headline)
                ForEach(EventType.allCases, id: \.self) { eventType in
                    EventTypePill(eventType: eventType, size: .large)
                }
            }
        }
        .padding()
    }
}
