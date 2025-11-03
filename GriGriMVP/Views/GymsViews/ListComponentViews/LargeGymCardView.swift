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
    @State private var showingMapView = false
    
    var body: some View {
        Button(action: {
            viewModel.selectGym(gym)
        }) {
            VStack(spacing: 4) {
                // Top section: Gym info and Map button horizontally aligned
                HStack(spacing: 8) {
                    // Gym profile image - use cached image view
                    CachedGymImageView(gym: gym, size: 56)

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
                    
                    // Map button
                    if #available(iOS 26.0, *) {
                        Button(action: {
                            showingMapView = true
                        }) {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.appPrimary)
                                .background(AppTheme.appContentBG)
                        }
                        .buttonStyle(.glass)
                    } else {
                        Button(action: {
                            showingMapView = true
                        }) {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.appPrimary)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.appContentBG)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.appPrimary.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                             
                }
                
                // Climbing type icons with labels
                HStack(spacing: 20) {
                    Spacer()
                    ForEach(gym.climbingType.sortedForDisplay(), id: \.self) { type in
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
            .appCardShadow()
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $showingMapView) {
            GymsMapView(viewModel: viewModel, selectedGymId: gym.id)
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
