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
            VStack(alignment: .center, spacing: 16) {
                // Profile Image
                profileImageView
                
                // Gym Name
                Text(viewModel.gym.name)
                    .font(.appHeadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                
                // Gym Location
                locationView
                
                // Climbing Types Icons
                climbingTypesIconsView
                
                // Action Buttons (Favorite & Visit)
                actionButtonsView
                
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
            .padding()
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
            Button(action: {
                viewModel.toggleFavorite()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    Text("Favourite")
                        .font(.appButtonPrimary)

                }
                .foregroundColor(viewModel.isFavorite ? AppTheme.appSecondary : AppTheme.appTextButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(viewModel.isFavorite ? Color.clear : AppTheme.appSecondary)
                .overlay(
                    viewModel.isFavorite ? 
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(AppTheme.appSecondary, lineWidth: 1) : nil
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            // Visit Button (Placeholder)
            Button(action: {
                // Placeholder action
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                    Text("Visit")
                        .font(.appButtonPrimary)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(AppTheme.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Events")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.gymEvents.prefix(5)) { event in
                            EventCardView(
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationView {
        GymProfileView(gym: SampleData.gyms[0])
    }
}
