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
    @ObservedObject var viewModel: GymsViewModel
    let onDismiss: () -> Void
    let onVisit: (Gym) -> Void
    @State private var dragOffset: CGFloat = 0 // For drag gesture
    @State private var isCompact: Bool = false // Compact vs expanded state

    var body: some View {
        VStack {
            Spacer() // Pushes the sheet to the bottom

            VStack(spacing: 8) {
                // Handle indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .padding(.trailing, 4)
                }
                .padding(.top, -4)

                gymInfoSection
                    .padding(.top, -8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Tap to expand when compact
                        if isCompact {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isCompact = false
                            }
                        }
                    }

                if !isCompact {
                    climbingTypesSection
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    actionButtons
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 20)
            .background(AppTheme.appContentBG)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
            .offset(y: dragOffset)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Allow both up and down drags
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let swipeDistance = value.translation.height
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if swipeDistance < -50 && isCompact {
                                // Swipe up when compact -> expand
                                isCompact = false
                                dragOffset = 0
                            } else if swipeDistance > 100 && !isCompact {
                                // Swipe down when expanded -> compact
                                isCompact = true
                                dragOffset = 0
                            } else if swipeDistance > 50 && isCompact {
                                // Swipe down when compact -> dismiss
                                onDismiss()
                            } else {
                                // Not enough swipe -> return to position
                                dragOffset = 0
                            }
                        }
                    }
                )
        }
        .clipped()
        .onChange(of: gym.id) { _ in
            // Reset to expanded when gym changes
            isCompact = false
        }
    }
    
    // MARK: - Component Sections
    
    private var gymInfoSection: some View {
        HStack(spacing: 8) {
            // Use cached image view for better performance and stability
            CachedGymImageView(gym: gym, size: 64)

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
            // Directly observe favoriteGyms to ensure reactivity
            let isFavorite = viewModel.favoriteGyms.contains(where: { $0.id == gym.id })
            PrimaryActionButton.toggle(
                isFavorite ? "Favourited" : "Favourite",
                isEngaged: isFavorite
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
            ForEach(gym.climbingType.sortedForDisplay(), id: \.self) { type in
                VStack(spacing: 2) {
                    climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(AppTheme.appPrimary)
                    
                    Text(formatClimbingType(type))
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
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
