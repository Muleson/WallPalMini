//
//  CompactEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct HomeCompactEventCard: View {
    let title: String
    let subtitle: String?
    let backgroundColor: Color
    let mediaItem: MediaItem?
    let gymProfileImage: MediaItem?
    let onTap: () -> Void
    
    init(title: String, subtitle: String? = nil, backgroundColor: Color, mediaItem: MediaItem? = nil, gymProfileImage: MediaItem? = nil, onTap: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.mediaItem = mediaItem
        self.gymProfileImage = gymProfileImage
        self.onTap = onTap
    }
    
    // Convenience initializer for EventItem
    init(event: EventItem, onTap: @escaping () -> Void) {
        self.title = event.name.uppercased()
        self.subtitle = event.host.name.uppercased()
        self.mediaItem = event.mediaItems?.first // Use first media item if available
        self.gymProfileImage = event.host.profileImage // Use gym's profile image
        
        // Choose background color based on event type
        switch event.eventType {
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
        case .gymClass:
            self.backgroundColor = Color.red.opacity(0.8)
        }
        

        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    // Background (color or media)
                    if let mediaItem = mediaItem {
                        AsyncImage(url: mediaItem.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 270)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(backgroundColor)
                                .frame(width: 180, height: 270)
                        }
                    } else {
                        Rectangle()
                            .fill(backgroundColor)
                            .frame(width: 180, height: 270)
                    }
                    
                    // Sharp gradient overlay from event type color to clear
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.4),
                            .init(color: AppTheme.appPrimary.opacity(0.8), location: 0.8),
                            .init(color: AppTheme.appPrimary, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Overlay content
                    overlayContent
                }
                .frame(width: 180, height: 270)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var overlayContent: some View {
        ZStack {
            // Main content area
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Main title with dynamic font sizing
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .allowsTightening(true)
                        
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
                    
                    // Empty space to prevent text from overlapping with gym logo
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // Fixed position gym logo
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Gym profile image or fallback icon - fixed position
                    if let gymProfileImage = gymProfileImage {
                        AsyncImage(url: gymProfileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        } placeholder: {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "building.2")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                        }
                    } else {
                        // Default fallback icon
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.4))
                            )
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // Preview with different event types from sample data
        HomeCompactEventCard(event: SampleData.events[0]) {
            print("Tapped event: \(SampleData.events[0].name)")
        }
        
        HomeCompactEventCard(event: SampleData.events[1]) {
            print("Tapped event: \(SampleData.events[1].name)")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
