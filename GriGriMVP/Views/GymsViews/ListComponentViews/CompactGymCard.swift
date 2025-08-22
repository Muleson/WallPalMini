//
//  CompactGymCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 15/08/2025.
//

import SwiftUI

struct CompactGymCard: View {
    let gym: Gym
    @ObservedObject var viewModel: GymsViewModel
    @State private var showingVisitOptions = false
    @State private var gymToVisit: Gym?
    @State private var navigateToGymProfile = false
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Gym profile image
                if let profileImage = gym.profileImage {
                    AsyncImage(url: profileImage.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "building.2")
                                    .foregroundColor(AppTheme.appPrimary)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "building.2")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Gym name
                    Text(gym.name)
                        .font(.appCardTitleSmall)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .truncationMode(.tail)
                        .foregroundColor(AppTheme.appTextPrimary)
                    
                    // Distance to gym
                    if let distance = viewModel.distanceToGym(gym) {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            // Climbing type icons
            HStack() {
                Spacer()
                ForEach(gym.climbingType, id: \.self) { type in
                    climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(AppTheme.appPrimary)
                }
                Spacer()
            }
            PrimaryActionButton(title: "Visit",
                                style: .primary,
                                size: .compact) {
                gymToVisit = gym
                showingVisitOptions = true
            }
        }
        .frame(width: 200, height: 140)
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
        .gymVisitDialog(
            isPresented: $showingVisitOptions,
            gym: gymToVisit,
            onViewInMaps: {
                if let gym = gymToVisit {
                    viewModel.openGymInMaps(gym)
                }
                showingVisitOptions = false
                gymToVisit = nil
            },
            onViewProfile: {
                navigateToGymProfile = true
                showingVisitOptions = false
                gymToVisit = nil
            }
        )
        .navigationDestination(isPresented: $navigateToGymProfile) {
            GymProfileView(gym: gym)
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
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CompactGymCard(
                gym: SampleData.gyms[0],
                viewModel: GymsViewModel(appState: AppState())
            )
            
            CompactGymCard(
                gym: SampleData.gyms[1],
                viewModel: GymsViewModel(appState: AppState())
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
