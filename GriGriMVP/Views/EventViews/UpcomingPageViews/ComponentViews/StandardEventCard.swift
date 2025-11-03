//
//  StandardEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/08/2025.
//

import SwiftUI

struct StandardEventCard: View {
    let event: EventItem
    let onTap: () -> Void
    var onGymTap: ((Gym) -> Void)? = nil
    
    // MARK: - Date/Time Formatting
    
    private var eventDateFormatted: String {
        let formatter = DateFormatter()
        
        if event.frequency != nil {
            // For recurring events, show the day of the week
            formatter.dateFormat = "EEEE"
            return formatter.string(from: event.startDate)
        } else {
            // For one-off events, show the date
            formatter.dateFormat = "MMM d"
            return formatter.string(from: event.startDate)
        }
    }
    
    private var eventTimeFormatted: String {
        if let frequency = event.frequency {
            // For recurring events, show frequency and time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mma"
            let time = timeFormatter.string(from: event.startDate)
            return "\(frequency.displayName) • \(time)"
        } else {
            // For one-off events, show start-end time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            let startTime = formatter.string(from: event.startDate)
            let endTime = formatter.string(from: event.endDate)
            return "\(startTime) - \(endTime)"
        }
    }
    
    private var fallbackGradient: LinearGradient {
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Event media section (left side)
                eventMediaSection
                
                // Event details section (right side)
                eventDetailsSection
            }
            .frame(height: 140)
            .background(AppTheme.appContentBG)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .appCardShadow()
        }
    .buttonStyle(PlainButtonStyle())
    .padding(.vertical, 4) // Added vertical padding
    }
    
    private var eventMediaSection: some View {
        Group {
            if let eventMedia = event.mediaItems?.first {
                AsyncImage(url: eventMedia.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 94, height: 140)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(fallbackGradient)
                        .frame(width: 94, height: 140)
                }
            } else {
                Rectangle()
                    .fill(fallbackGradient)
                    .frame(width: 94, height: 140)
            }
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: Host info and event tag
            HStack {
                // Host gym info - tappable
                Button(action: {
                    onGymTap?(event.host)
                }) {
                    HStack(spacing: 6) {
                        CachedGymImageView(gym: event.host, size: 18)

                        Text(event.host.name)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.appPrimary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Event type tag
                Text(event.eventType.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tagBackgroundColor)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 6)
            
            // Event name
            Text(event.name)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)
            
            // Date and time info
            VStack(alignment: .leading, spacing: 2) {
                Text(eventDateFormatted)
                    .font(.system(size: 13, weight: .light, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                
                Text(eventTimeFormatted)
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundColor(AppTheme.appTextLight)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                PrimaryActionButton.outlineCompact("Save") {
                    // TODO: Implement save action
                    print("Save button tapped for event: \(event.name)")
                }
                
                PrimaryActionButton.custom("View", style: .primary, size: .compact, action: onTap)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Different event types to showcase versatility
        StandardEventCard(event: SampleData.events[0]) {
            print("Tapped event: \(SampleData.events[0].name)")
        }
        
        StandardEventCard(event: SampleData.events[1]) {
            print("Tapped event: \(SampleData.events[1].name)")
        }
        
        StandardEventCard(event: SampleData.events[2]) {
            print("Tapped event: \(SampleData.events[2].name)")
        }
        
        StandardEventCard(event: SampleData.events[3]) {
            print("Tapped event: \(SampleData.events[3].name)")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

