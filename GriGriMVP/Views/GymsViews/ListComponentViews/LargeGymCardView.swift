//
//  LargeGymCardView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 16/08/2025.
//

import SwiftUI

struct LargeGymCardView: View {
    let gym: Gym
    @ObservedObject var viewModel: GymsViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            // Top section: Gym info and Visit button horizontally aligned
            HStack(spacing: 8) {
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
                
                // Gym details
                VStack(alignment: .leading, spacing: 4) {
                    Text(gym.name)
                        .font(.appCardTitleLarge)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .truncationMode(.tail)
                        .foregroundColor(AppTheme.appTextPrimary)
                    
                    if let distance = viewModel.distanceToGym(gym) {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Visit button
                PrimaryActionButton(title: "Visit",
                                    style: .primary,
                                    size: .compact) {
                }
                                    .frame(width: 96)
            }
            
            // Climbing type icons with labels
            HStack(spacing: 20) {
                Spacer()
                ForEach(gym.climbingType, id: \.self) { type in
                    VStack(spacing: -2) {
                        climbingTypeIcon(for: type)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppTheme.appPrimary)
                        
                        Text(climbingTypeLabel(for: type))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
    
    private func climbingTypeLabel(for type: ClimbingTypes) -> String {
        switch type {
        case .bouldering:
            return "Bouldering"
        case .sport:
            return "Sport"
        case .board:
            return "Board"
        case .gym:
            return "Gym"
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            LargeGymCardView(
                gym: SampleData.gyms[0],
                viewModel: GymsViewModel(appState: AppState())
            )
            
            LargeGymCardView(
                gym: SampleData.gyms[1],
                viewModel: GymsViewModel(appState: AppState())
            )
        }
        .padding(.horizontal, 12) // 24px total horizontal padding (12 on each side)
    }
    .background(Color(.systemGroupedBackground))
}
