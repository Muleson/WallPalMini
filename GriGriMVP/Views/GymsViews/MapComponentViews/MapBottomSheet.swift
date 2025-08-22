//
//  MapBottomSheet.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/08/2025.
//

import SwiftUI
import MapKit

struct MapBottomSheet: View {
    let gym: Gym
    let viewModel: GymsViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var showingVisitOptions = false
    @State private var navigateToGymProfile = false
    
    let onDismiss: () -> Void
    let onVisit: (Gym) -> Void
    
    var body: some View {
        VStack {
            Spacer() // Pushes the sheet to the bottom
            
            VStack(spacing: 16) {
                // Handle indicator
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 4)
                    
                    gymInfoSection
                }
                .padding(.top, 8)
                
                climbingTypesSection
                
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(height: 300)
            .background(AppTheme.appContentBG)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
            .offset(y: dragOffset)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeOut(duration: 0.3)) {
                            if value.translation.height > 100 {
                                onDismiss()
                            }
                            dragOffset = 0
                        }
                    }
                )
        }
        .clipped()
    }
    
    // MARK: - Component Sections
    
    private var gymInfoSection: some View {
        HStack(spacing: 8) {
            if let profileImage = gym.profileImage {
                AsyncImage(url: profileImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } placeholder: {
                    gymImagePlaceholder(size: 64)
                }
            } else {
                gymImagePlaceholder(size: 64)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(gym.name)
                    .font(.appHeadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if let distance = viewModel.distanceToGym(gym) {
                    Text(distance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            .frame(height: 64)
            
            Spacer()
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            PrimaryActionButton.toggle(
                viewModel.isGymFavorited(gym) ? "Favourited" : "Favourite",
                isEngaged: viewModel.isGymFavorited(gym)
            ) {
                Task {
                    await viewModel.toggleFavoriteGym(gym)
                }
            }
            
            PrimaryActionButton.primary("Visit") {
                onVisit(gym)
            }
        }
    }
    
    private var climbingTypesSection: some View {
        HStack {
            ForEach(gym.climbingType, id: \.self) { type in
                VStack(spacing: 6) {
                    climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(AppTheme.appPrimary)
                    
                    Text(formatClimbingType(type))
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func formatClimbingType(_ type: ClimbingTypes) -> String {
        switch type {
        case .bouldering: return "Boulder"
        case .sport: return "Sport"
        case .board: return "Board"
        case .gym: return "Gym"
        }
    }
    
    private func gymImagePlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(AppTheme.appSecondary.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "building.2.fill")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(AppTheme.appPrimary)
            )
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    MapBottomSheet(
        gym: SampleData.gyms[0],
        viewModel: GymsViewModel(appState: AppState()),
        onDismiss: {},
        onVisit: { _ in }
    )
}
