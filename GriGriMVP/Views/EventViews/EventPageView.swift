//
//  EventPageView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/06/2025.
//

import SwiftUI

struct EventPageView: View {
    let event: EventItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Event Name
                Text(event.name)
                    .font(.appHeadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                    .padding()
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Event date
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatEventDate(event.eventDate))
                        .font(.appSubheadline)
                        .foregroundStyle(AppTheme.appTextPrimary)
                    Text(formatEventTime(event.eventDate))
                        .font(.appUnderline)
                        .foregroundColor(AppTheme.appTextLight)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Host and location section
                HStack {
                    // Profile image placeholder - assuming we need to access host's profile image
                    if let profileImage = event.host.profileImage {
                        AsyncImage(url: profileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 48)
                        }
                    } else {
                        Image(systemName: "building.2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray)
                    }
                    Text(event.host.name)
                        .font(.appButtonPrimary)
                        .foregroundStyle(AppTheme.appPrimary)
                    
                    Spacer()
                    
                    // Maps button placeholder
                    Button(action: {
                        // TODO: Open maps with event location
                    }) {
                        HStack {
                            Image(systemName: "location.magnifyingglass")
                                .padding(.trailing, -4)
                            Text("View in Maps")
                        }
                        .font(.appButtonSecondary)
                        .foregroundStyle(AppTheme.appTextButton)
                        .padding(.horizontal,8)
                        .padding(.vertical, 6)
                        .background(AppTheme.appSecondary)
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Event media section
                if let mediaItems = event.mediaItems, !mediaItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(mediaItems, id: \.id) { mediaItem in
                                AsyncImage(url: mediaItem.url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 200, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(AppTheme.appSecondary)
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    
                }
                
                // Description section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.appSubheadline)
                        .foregroundStyle(AppTheme.appPrimary)
                    
                    Text(event.description)
                        .font(.appBody)
                        .lineLimit(nil)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                Spacer(minLength: 20)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating register button
            if event.registrationRequired {
                Button(action: {
                    if let registrationLink = event.registrationLink,
                       let url = URL(string: registrationLink) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Register")
                    }
                    .font(.appButtonPrimary)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.appPrimary)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        EventPageView(event: SampleData.events[0])
    }
}
