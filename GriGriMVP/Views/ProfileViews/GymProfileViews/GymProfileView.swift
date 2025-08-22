//
//  GymProfileView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct GymProfileView: View {
    @StateObject private var viewModel: GymProfileViewModel
    @Environment(\.openURL) private var openURL
    @State private var showVisitOptions: Bool = false
    @State private var selectedEvent: EventItem? = nil
    
    init(gym: Gym) {
        _viewModel = StateObject(wrappedValue: GymProfileViewModel(gym: gym))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Profile Image
                profileImageView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Gym Name
                Text(viewModel.gym.name)
                    .font(.appHeadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Gym Location
                locationView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Climbing Types Icons
                climbingTypesIconsView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Action Buttons (Favorite & Visit)
                actionButtonsView
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Upcoming Events Section
                upcomingEventsSection
                
                // Amenities Section
                amenitiesSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackgroundBG)
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
        .confirmationDialog("Visit \(viewModel.gym.name)", isPresented: $showVisitOptions, titleVisibility: .visible) {
            Button("Open in Maps") {
                openMap()
            }

            Button("View Website (TODO)") {
                // TODO: open website when gym website property is available
            }

            Button("Cancel", role: .cancel) { }
        }
        .navigationDestination(item: $selectedEvent) { event in
            EventPageView(event: event)
        }
    }
    
    private var profileImageView: some View {
        Group {
            if let profileImage = viewModel.gym.profileImage {
                AsyncImage(url: profileImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "building.2")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 128, height: 128)
                .clipShape(Circle())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    private var locationView: some View {
        HStack {
            Text(viewModel.gym.location.formattedAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var climbingTypesIconsView: some View {
        HStack(spacing: 36) {
            ForEach(viewModel.gym.climbingType, id: \.self) { type in
                VStack(spacing: -4) {
                    climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .foregroundColor(AppTheme.appPrimary)
                    
                    Text(viewModel.formatClimbingType(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func climbingTypeIcon(for type: ClimbingTypes) -> Image {
        switch type {
        case .bouldering:
            return AppIcons.boulder
        case .sport:
            return AppIcons.sport
        case .board:
            return AppIcons.board
        case .gym:
            return AppIcons.gym
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Favorite Button
            PrimaryActionButton.toggle(
                viewModel.isFavorite ? "Favourited" : "Favourite",
                isEngaged: viewModel.isFavorite
            ) {
                viewModel.toggleFavorite()
            }
            
            // Visit Button (Placeholder)
            PrimaryActionButton.primary("Visit") {
                showVisitOptions = true
            }
        }
        .padding(.horizontal, 24)
    }

    private func openMap() {
        let lat = viewModel.gym.location.latitude
        let lon = viewModel.gym.location.longitude
        let name = viewModel.gym.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?ll=\(lat),\(lon)&q=\(name)"
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Featured Event Section - show if there's a next featured event
            if let featuredEvent = viewModel.nextFeaturedEvent {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Upcoming Event")
                            .font(.appSubheadline)
                            .foregroundStyle(AppTheme.appTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    HomeFeaturedEventCard(
                        event: featuredEvent,
                        onView: {
                            selectedEvent = featuredEvent
                        },
                        onRegister: {
                            // TODO: Handle registration
                        },
                        onAddToCalendar: {
                            // TODO: Add to calendar
                        }
                    )
                    .padding(.horizontal)
                }
            }
            
            // Gym Classes Section - show if there are upcoming classes
            if !viewModel.upcomingClassEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Classes")
                            .font(.appSubheadline)
                            .foregroundStyle(AppTheme.appTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.upcomingClassEvents.prefix(10)) { event in
                                CompactEventCard(event: event) {
                                    selectedEvent = event
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.gym.amenities.isEmpty {
                HStack {
                    Text("Amenities")
                        .font(.appSubheadline)
                        .foregroundStyle(AppTheme.appTextPrimary)
                    Spacer()
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(viewModel.gym.amenities, id: \.self) { amenity in
                        HStack(spacing: 8) {
                            AmmenitiesIcons.icon(for: amenity)
                                .foregroundColor(AppTheme.appPrimary)
                            Text(amenity.rawValue)
                                .font(.appBody)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationView {
        GymProfileView(gym: SampleData.gyms[1])
    }
}
