//
//  GymMapAnnotationView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 04/08/2025.
//

import SwiftUI

struct GymMapAnnotationView: View {
    let gym: Gym
    let isFavorite: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Main pin button
            Button(action: onTap) {
                ZStack {
                    // Pin background
                    Circle()
                        .fill(.white)
                        .frame(width: pinSize, height: pinSize)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(AppTheme.appPrimary, lineWidth: 3)
                            .frame(width: pinSize, height: pinSize)
                    }
                    
                    // Gym icon or profile image
                    if let profileImage = gym.profileImage {
                        AsyncImage(url: profileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: pinSize - 6, height: pinSize - 6)
                                .clipShape(Circle())
                        } placeholder: {
                            gymIconView
                        }
                    } else {
                        gymIconView
                    }
                    
                    // Favorite indicator
                    if isFavorite {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(.white)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppTheme.appPrimary)
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        }
                    }
                }
            }
            
            // Gym name label (only show when selected)
            if isSelected {
                Text(gym.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .zIndex(isSelected ? 1 : 0)
    }
    
    // MARK: - Computed Properties
    
    private var pinSize: CGFloat {
        isSelected ? 44 : 36
    }
    
    private var gymIconView: some View {
        let iconName = primaryClimbingTypeIcon
        
        return Image(systemName: iconName)
            .font(.system(size: pinSize * 0.5, weight: .semibold))
            .foregroundColor(AppTheme.appPrimary)
    }
    
    private var primaryClimbingTypeIcon: String {
        if gym.climbingType.contains(.bouldering) {
            return "circle.hexagonpath"
        } else if gym.climbingType.contains(.sport) {
            return "figure.climbing"
        } else if gym.climbingType.contains(.board) {
            return "rectangle.grid.3x2"
        } else {
            return "building.2.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Regular gym pin
        GymMapAnnotationView(
            gym: SampleData.gyms[0],
            isFavorite: false,
            isSelected: false,
            onTap: {}
        )
        
        // Favorite gym pin
        GymMapAnnotationView(
            gym: SampleData.gyms[0],
            isFavorite: true,
            isSelected: false,
            onTap: {}
        )
        
        // Selected gym pin
        GymMapAnnotationView(
            gym: SampleData.gyms[0],
            isFavorite: false,
            isSelected: true,
            onTap: {}
        )
        
        // Selected + favorite gym pin
        GymMapAnnotationView(
            gym: SampleData.gyms[0],
            isFavorite: true,
            isSelected: true,
            onTap: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
