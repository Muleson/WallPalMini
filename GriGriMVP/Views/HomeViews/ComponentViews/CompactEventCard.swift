//
//  CompactEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct CompactEventCard: View {
    let title: String
    let subtitle: String?
    let backgroundColor: Color
    let systemImage: String?
    let onTap: () -> Void
    
    init(title: String, subtitle: String? = nil, backgroundColor: Color, systemImage: String? = nil, onTap: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.systemImage = systemImage
        self.onTap = onTap
    }
    
    // Convenience initializer for EventItem
    init(event: EventItem, onTap: @escaping () -> Void) {
        self.title = event.name.uppercased()
        self.subtitle = event.host.name.uppercased()
        
        // Choose background color based on event type
        switch event.type {
        case .competition:
            self.backgroundColor = Color.yellow.opacity(0.8)
        case .social:
            self.backgroundColor = Color.green.opacity(0.8)
        case .openDay:
            self.backgroundColor = Color.blue.opacity(0.8)
        case .settingTaster:
            self.backgroundColor = Color.purple.opacity(0.8)
        case .opening:
            self.backgroundColor = Color.orange.opacity(0.8)
        }
        
        self.systemImage = "figure.climbing"
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: 200, height: 240)
                    .overlay(
                        overlayContent
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var overlayContent: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Main title
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    // Subtitle if provided
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Icon
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

// Pre-defined card variants
extension CompactEventCard {
    static func communityClimb(onTap: @escaping () -> Void) -> CompactEventCard {
        CompactEventCard(
            title: "COMMUNITY\nCLIMB",
            subtitle: "CLIMB • CONNECT • CELEBRATE",
            backgroundColor: Color.green.opacity(0.8),
            systemImage: "figure.climbing",
            onTap: onTap
        )
    }
    
    static func vertigoFiesta(onTap: @escaping () -> Void) -> CompactEventCard {
        CompactEventCard(
            title: "VERTIGO\nFIESTA",
            subtitle: "CLIMB • GET TOGETHER • PARTY",
            backgroundColor: Color.blue.opacity(0.8),
            systemImage: "figure.climbing",
            onTap: onTap
        )
    }
    
    static func routeSetting(onTap: @escaping () -> Void) -> CompactEventCard {
        CompactEventCard(
            title: "ROUTE\nSETTING",
            subtitle: "WORKSHOP • LEARN • CREATE",
            backgroundColor: Color.purple.opacity(0.8),
            systemImage: "hammer.fill",
            onTap: onTap
        )
    }
    
    static func beginnerSession(onTap: @escaping () -> Void) -> CompactEventCard {
        CompactEventCard(
            title: "BEGINNER\nSESSION",
            subtitle: "LEARN • PRACTICE • GROW",
            backgroundColor: Color.orange.opacity(0.8),
            systemImage: "graduationcap.fill",
            onTap: onTap
        )
    }
}
