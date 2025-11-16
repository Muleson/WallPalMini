//
//  FeaturedEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct HomeFeaturedEventCard: View {
    let event: EventItem
    let onView: () -> Void
    let onRegister: () -> Void
    let onAddToCalendar: (() -> Void)?
    let onSave: () -> Void
    let isSaved: Bool
    var onGymTap: ((Gym) -> Void)? = nil

    @State private var showShareSheet = false
    @StateObject private var colorService = MediaColorService.shared

    private var eventDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: event.startDate)
    }
    
    private var eventTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        let startTime = formatter.string(from: event.startDate)
        
        // Show range with end date
        let endTime = formatter.string(from: event.endDate)
        return "\(startTime) - \(endTime)"
    }
    
    private var prominentColor: Color {
        // Use extracted color from media with neutral fallback
        colorService.getColor(for: event.mediaItems?.first, fallback: AppTheme.appPrimary)
    }

    private var fallbackGradient: LinearGradient {
        // Fallback gradient only used when no media is available
        let gradients: [LinearGradient] = [
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ]

        let index = abs(event.id.hashValue) % gradients.count
        return gradients[index]
    }
    
    var body: some View {
        Button(action: onView) {
            HStack(spacing: 0) {
                // Event media section - clean image display
                eventMediaSection
                
                // Event details section - text content on right
                eventDetailsSection
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.appPrimary, lineWidth: 2)
            )
            .appCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
        .shareSheet(isPresented: $showShareSheet, activityItems: ShareLinkHelper.eventShareItems(event: event))
    }
    
    private var eventMediaSection: some View {
        Group {
            // Use event mediaItems[0] if available, otherwise fallback gradient
            if let eventMedia = event.mediaItems?.first {
                AsyncImage(url: eventMedia.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 240)
                        .clipped()
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(prominentColor.opacity(0.8))
                            .frame(width: 160, height: 240)

                        NegativeEventTypeIcons.icon(for: event.eventType)
                            .resizable()
                            .renderingMode(.original)
                            .interpolation(.high)
                            .antialiased(true)
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                    }
                }
            } else {
                Rectangle()
                    .fill(fallbackGradient)
                    .frame(width: 160, height: 240)
            }
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Host/venue info - made tappable
            HStack(spacing: 4) {
                // Display host gym's profile image with caching
                CachedGymImageView(gym: event.host, size: 20)

                Text(event.host.name)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.appPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .onTapGesture {
                onGymTap?(event.host)
            }
            
            // Event name - moved to details section
           Text(event.name)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Date
            Text(eventDateFormatted)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .lineLimit(1)
            
            // Time
            Text(eventTimeFormatted)
                .font(.system(size: 14, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextLight)
            
            // Event type tag
            HStack {
                Text(event.eventType.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tagBackgroundColor)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            Spacer()
            
            // Action buttons - stacked vertically for better fit
            VStack(spacing: 8) {
                PrimaryActionButton.custom(isSaved ? "Saved" : "Save", style: isSaved ? .engaged : .outline, size: .compact) {
                    onSave()
                }

                PrimaryActionButton(title: "Share",
                                    style: .primary,
                                    size: .compact) {
                    showShareSheet = true
                }
            }
        }
    .padding(12)
    .frame(height: 240)
    .background(AppTheme.appPrimary.opacity(0.15))
    }
    
    private var tagBackgroundColor: Color {
        switch event.eventType {
        case .competition:
            return Color.yellow.opacity(0.2)
        case .social:
            return Color.green.opacity(0.2)
        case .openDay:
            return Color.blue.opacity(0.2)
        case .settingTaster:
            return Color.purple.opacity(0.2)
        case .opening:
            return Color.orange.opacity(0.2)
        case .gymClass:
            return Color.red.opacity(0.2)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // Preview with different event types from sample data
        HomeFeaturedEventCard(
            event: SampleData.events[0], // Summer Send Festival (competition)
            onView: {
                print("View event: \(SampleData.events[0].name)")
            },
            onRegister: {
                print("Register for: \(SampleData.events[0].name)")
            },
            onAddToCalendar: {
                print("Add to calendar: \(SampleData.events[0].name)")
            },
            onSave: {
                print("Save event: \(SampleData.events[0].name)")
            },
            isSaved: false
        )

        HomeFeaturedEventCard(
            event: SampleData.events[1],
            onView: {
                print("View event: \(SampleData.events[1].name)")
            },
            onRegister: {
                print("Register for: \(SampleData.events[1].name)")
            },
            onAddToCalendar: {
                print("Add to calendar: \(SampleData.events[1].name)")
            },
            onSave: {
                print("Save event: \(SampleData.events[1].name)")
            },
            isSaved: true
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
