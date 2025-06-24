//
//  GymCardView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 18/06/2025.
//

import SwiftUI

struct GymCardView: View {
    let gym: Gym
    let events: [EventItem]
    @ObservedObject var viewModel: GymsViewModel
    @State private var showingLocationOptions = false
    
    var upcomingEvents: [EventItem] {
        let now = Date()
        return events
            .filter { $0.eventDate > now }
            .sorted { $0.eventDate < $1.eventDate }
    }
    
    var isFavorited: Bool {
        viewModel.isGymFavorited(gym)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with gym info and action buttons
            HStack(spacing: 12) {
                // Gym profile image
                if let profileImage = gym.profileImage {
                    AsyncImage(url: profileImage.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "building.2")
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "building.2")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Gym name
                    Text(gym.name)
                        .font(.appSubheadline)
                        .lineLimit(1)
                        .foregroundColor(AppTheme.appTextPrimary)
                    
                    // Distance if available
                    if let distance = viewModel.distanceToGym(gym) {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Favorite button
                /*Button(action: {
                    Task {
                        await viewModel.toggleFavoriteGym(gym)
                    }
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : .gray)
                        .font(.system(size: 20))
                } */
                
                // Visit button
                Button("Visit") {
                    showingLocationOptions = true
                }
                .font(.appButtonSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(AppTheme.appPrimary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Horizontal scroll view of upcoming events
            if !upcomingEvents.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(upcomingEvents) { event in
                            GymEventCardView(event: event)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // No upcoming events placeholder
                HStack {
                    Text("No upcoming events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .confirmationDialog("Visit Gym", isPresented: $showingLocationOptions) {
            Button("View in Maps") {
                viewModel.openGymInMaps(gym)
            }
            Button("View Gym Profile") {
                // Navigate to gym profile
                // This would typically use navigation
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How would you like to visit \(gym.name)?")
        }
    }
}

struct GymEventCardView: View {
    let event: EventItem
    
    var body: some View {
        NavigationLink(destination: EventPageView(event: event)) {
            VStack(alignment: .leading, spacing: 8) {
                // Event image
                if let mediaItems = event.mediaItems, !mediaItems.isEmpty {
                    AsyncImage(url: mediaItems[0].url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 130, height: 160)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 130, height: 160)
                        .overlay(
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                }
                
                // Event date
                Text(formatEventDate(event.eventDate))
                    .font(.appUnderline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
            }
            .frame(width: 130)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 2, y: 2)
            .padding(.bottom, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.day], from: now, to: date)
        
        if let days = components.day, days >= 0 && days < 7 {
            switch days {
            case 0:
                return "Today"
            case 1:
                return "Tomorrow"
            default:
                return "\(days) days"
            }
        } else {
            // Use short date format for events beyond a week
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Gym with events
            GymCardView(
                gym: SampleData.gyms[0],
                events: SampleData.events,
                viewModel: GymsViewModel(appState: AppState())
            )
            
            // Gym without events
            GymCardView(
                gym: SampleData.gyms[1],
                events: [],
                viewModel: GymsViewModel(appState: AppState())
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

