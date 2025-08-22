//
//  EventCompactView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 13/05/2025.
//

import SwiftUI

struct EventCardView: View {
    let event: EventItem
    let onFavorite: () -> Void
    let isFavorite: Bool
    
    var body: some View {
        NavigationLink(destination: EventPageView(event: event)) {
            VStack(alignment: .leading, spacing: 0) {
                // Media display
                ZStack(alignment: .topTrailing) {
                    if let mediaItems = event.mediaItems, !mediaItems.isEmpty {
                        // Show the first image from the media array
                        AsyncImage(url: mediaItems[0].url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 200, height: 250)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 250)
                            .overlay(
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
        
                    // Favorite button
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .font(.system(size: 22))
                            .padding(8)
                            .shadow(radius: 2)
                    }
                    .padding([.top, .trailing], 8)
                }

                // Info box at bottom
                VStack(spacing: 8) {
                    // Event name
                    HStack {
                        Text(event.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    // Gym info and time on same line
                    HStack {
                        // Gym profile picture
                        if let profileImage = event.host.profileImage {
                            AsyncImage(url: profileImage.url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                            }
                        } else {
                            Image(systemName: "building.2")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                        }
                        
                        // Gym name text
                        Text(event.host.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Time relative to current date
                        Text(timeUntilEvent(event.startDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color.white)
            }
            .frame(width: 200, height: 316)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .appCardShadow()
        }
        .buttonStyle(PlainButtonStyle()) // Prevents the NavigationLink from interfering with button interactions
    }
    
    // Helper function to calculate relative time until event
    private func timeUntilEvent(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if date < now {
            return "Ended"
        }
        
        let components = calendar.dateComponents([.day, .hour], from: now, to: date)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "Tomorrow" : "\(days) days"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hours"
        } else {
            return "Soon"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Upcoming event with image
        EventCardView(
            event: SampleData.events[0],
            onFavorite: {},
            isFavorite: false
        )
        .frame(width: 250)
        
        // Event happening today with image
        EventCardView(
            event: SampleData.events[1],
            onFavorite: {},
            isFavorite: true
        )
        .frame(width: 250)
        
        // Past event without image
        EventCardView(
            event: SampleData.events[2],
            onFavorite: {},
            isFavorite: false
        )
        .frame(width: 250)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
