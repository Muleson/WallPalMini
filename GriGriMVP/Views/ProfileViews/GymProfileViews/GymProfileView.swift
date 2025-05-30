//
//  GymProfileView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct GymProfileView: View {
    @StateObject private var viewModel: GymProfileViewModel
    
    init(gym: Gym) {
        _viewModel = StateObject(wrappedValue: GymProfileViewModel(gym: gym))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Cover photo with floating favorite button
                coverPhotoView
                
                // Gym profile section
                profileSection
                
                // Climbing types
                climbingTypesSection
                
                // Amenities section
                amenitiesSection
                
                // Location section
                locationSection
                
                // Events section grouped by type
                eventsSection
            }
        }
        .edgesIgnoringSafeArea(.top) // Make cover photo edge-to-edge
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refreshGymDetails()
            viewModel.loadGymEvents()
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
    
    private var coverPhotoView: some View {
        ZStack(alignment: .bottomTrailing) {
            // Cover photo
            if let profileImage = viewModel.gym.profileImage {
                AsyncImage(url: profileImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    )
            }
            
            // Floating favorite button
            Button(action: {
                // Toggle favorite status
                viewModel.toggleFavorite()
            }) {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(viewModel.isFavorite ? .red : .white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .shadow(radius: 3)
                    )
            }
            .padding(16)
        }
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Gym name
            Text(viewModel.gym.name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Description (if available)
            if let description = viewModel.gym.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    private var climbingTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Climbing Styles")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.gym.climbingType, id: \.self) { type in
                        Text(viewModel.formatClimbingType(type))
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.appAccent.opacity(0.2))
                            .foregroundColor(AppTheme.appAccent)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.gym.amenities.isEmpty {
                Text("Amenities")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(viewModel.gym.amenities, id: \.self) { amenity in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.appAccent)
                            Text(amenity)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            if let address = viewModel.gym.location.address {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(AppTheme.appAccent)
                    Text(address)
                        .font(.subheadline)
                }
                .padding(.horizontal)
            } else {
                Text("Coordinates: \(viewModel.gym.location.latitude), \(viewModel.gym.location.longitude)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
            
            // Map placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    Image(systemName: "map")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                )
                .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Events")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            if viewModel.isLoadingEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.gymEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Group events by type
                ForEach(viewModel.groupedEvents.keys.sorted(), id: \.self) { category in
                    eventCategorySection(category: category, events: viewModel.groupedEvents[category] ?? [])
                }
            }
        }
    }
    
    private func eventCategorySection(category: String, events: [EventItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(events) { event in
                        EventCardCompactView(
                            event: event,
                            onFavorite: { viewModel.toggleEventFavorite(event: event) },
                            isFavorite: viewModel.isEventFavorited(event: event)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // A compact event card for horizontal scrolling
    struct EventCardCompactView: View {
        let event: EventItem
        var onFavorite: () -> Void
        var isFavorite: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Event image
                    if let mediaItems = event.mediaItems, !mediaItems.isEmpty {
                        AsyncImage(url: mediaItems[0].url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 200, height: 120)
                        .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 120)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Favorite button
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(8)
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(formattedDate(event.eventDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NavigationView {
        GymProfileView(gym: SampleData.gyms[0])
    }
}
