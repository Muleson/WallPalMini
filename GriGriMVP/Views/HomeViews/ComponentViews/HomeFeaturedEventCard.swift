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
    @State private var selectedGym: Gym?
    
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
        HStack(spacing: 0) {
            // Event media section - clean image display
            eventMediaSection
            
            // Event details section - text content on right
            eventDetailsSection
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                    Rectangle()
                        .fill(fallbackGradient)
                        .frame(width: 160, height: 240)
                }
            } else {
                Rectangle()
                    .fill(fallbackGradient)
                    .frame(width: 160, height: 240)
            }
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Host/venue info - made tappable
            Button(action: {
                selectedGym = event.host
            }) {
                HStack(spacing: 4) {
                    // Display host gym's profile image instead of house icon
                    AsyncImage(url: event.host.profileImage?.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(AppTheme.appTextLight.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "house.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.appTextLight)
                            )
                    }
                    
                    Text(event.host.name)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.appTextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Event name - moved to details section
          /*  Text(event.name)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .lineLimit(2) */
            
            // Date
            Text(eventDateFormatted)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .lineLimit(1)
            
            // Time
            Text(eventTimeFormatted)
                .font(.system(size: 14, weight: .regular, design: .rounded))
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
                PrimaryActionButton.outline("View") {
                    onView()
                }
                
                // Conditional button based on registration requirement
                if event.registrationRequired == true {
                    PrimaryActionButton(title: "Register",
                                        style: .primary,
                                        size: .standard) {
                        onRegister()
                    }
                } else {
                    PrimaryActionButton.primary("Add to Calendar") {
                        onAddToCalendar?()
                    }
                }
            }
        }
        .padding(16)
        .frame(height: 240)
        .background(Color(AppTheme.appContentBG))
        .navigationDestination(item: $selectedGym) { gym in
            GymProfileView(gym: gym)
        }
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
            }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
