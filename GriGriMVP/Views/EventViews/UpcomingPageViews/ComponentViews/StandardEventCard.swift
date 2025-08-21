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
    @State private var selectedGym: Gym?
    
    private var eventDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: event.startDate)
    }
    
    private var eventTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: event.startDate)
    }
    
    private var backgroundColor: Color {
        switch event.eventType {
        case .competition:
            return Color.yellow.opacity(0.8)
        case .social:
            return Color.green.opacity(0.8)
        case .openDay:
            return Color.blue.opacity(0.8)
        case .settingTaster:
            return Color.purple.opacity(0.8)
        case .opening:
            return Color.orange.opacity(0.8)
        case .gymClass:
            return Color.red.opacity(0.8)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    // Background (media or color with improved handling)
                    if let mediaItem = event.mediaItems?.first {
                        AsyncImage(url: mediaItem.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(backgroundColor)
                        }
                    } else {
                        Rectangle()
                            .fill(backgroundColor)
                    }
                    
                    // Refined gradient overlay
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.5),
                            .init(color: AppTheme.appPrimary.opacity(0.6), location: 0.8),
                            .init(color: AppTheme.appPrimary.opacity(0.9), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Content overlay
                    overlayContent
                }
                .frame(width: 200, height: 260)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .navigationDestination(item: $selectedGym) { gym in
            GymProfileView(gym: gym)
        }
    }
    
    private var overlayContent: some View {
        VStack {
            // Top section - Date badge
            HStack {
                VStack(spacing: 2) {
                    Text(eventDateFormatted)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.appPrimary)
                    Text(eventTimeFormatted)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.appPrimary.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Bottom section - Event info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        // Event title
                        Text(event.name.uppercased())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        
                        // Gym name - tappable
                        Button(action: {
                            selectedGym = event.host
                        }) {
                            Text(event.host.name)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Event type tag
                        Text(event.eventType.displayName)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Gym profile image
                    AsyncImage(url: event.host.profileImage?.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    } placeholder: {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 45, height: 45)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StandardEventCard(event: SampleData.events[0]) {
                print("Tapped event: \(SampleData.events[0].name)")
            }
            
            StandardEventCard(event: SampleData.events[1]) {
                print("Tapped event: \(SampleData.events[1].name)")
            }
        }
        
        HStack(spacing: 16) {
            StandardEventCard(event: SampleData.events[2]) {
                print("Tapped event: \(SampleData.events[2].name)")
            }
            
            StandardEventCard(event: SampleData.events[3]) {
                print("Tapped event: \(SampleData.events[3].name)")
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

