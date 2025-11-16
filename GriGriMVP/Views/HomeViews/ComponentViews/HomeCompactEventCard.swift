//
//  CompactEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct HomeCompactEventCard: View {
    let event: EventItem
    let onTap: () -> Void

    @StateObject private var colorService = MediaColorService.shared

    private var title: String {
        event.name.uppercased()
    }

    private var subtitle: String {
        event.host.name.uppercased()
    }

    private var prominentColor: Color {
        // Use extracted color from media with neutral fallback
        colorService.getColor(for: mediaItem, fallback: AppTheme.appPrimary)
    }

    private var backgroundColor: Color {
        prominentColor.opacity(0.8)
    }

    private var mediaItem: MediaItem? {
        event.mediaItems?.first
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
                            ZStack {
                                Rectangle()
                                    .fill(backgroundColor)
                                    .frame(width: 180, height: 270)

                                NegativeEventTypeIcons.icon(for: event.eventType)
                                    .resizable()
                                    .renderingMode(.original)
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                            }
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
            .appCardShadow()
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
                        
                        // Subtitle
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
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
                    
                    // Gym profile image - using cached view
                    CachedGymImageView(gym: event.host, size: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
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
