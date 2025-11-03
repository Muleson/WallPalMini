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
    
    var body: some View {
        Button(action: {
            viewModel.selectGym(gym)
        }) {
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    // Gym profile image - use cached image view
                    CachedGymImageView(gym: gym, size: 56)

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
                    ForEach(gym.climbingType.sortedForDisplay(), id: \.self) { type in
                        climbingTypeIcon(for: type)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(AppTheme.appPrimary)
                    }
                    Spacer()
                }
            }
            .frame(width: 180, height: 110)
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .appCardShadow()
        }
        .buttonStyle(.plain)
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
