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
    let onDismiss: () -> Void
    let onVisit: (Gym) -> Void
    
    @ObservedObject var viewModel: GymsViewModel
    
    @State private var dragOffset: CGFloat = 0 // For drag gesture
    @State private var showFullScreenProfile: Bool = false // Full-screen profile sheet

    // Offset to push sheet down and hide extended content by default
    private let defaultBottomOffset: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer() // Pushes the sheet to the bottom

                VStack(spacing: 8) {
                // Handle indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                gymInfoSection
                    .padding(.top, -8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Tap to show full profile
                        showFullScreenProfile = true
                    }

                climbingTypesSection

                actionButtons
                    .padding(.bottom, 4)

                // Hidden content area that's revealed when dragging up
                // This area is initially below the visible frame
                VStack(spacing: 0) {
                    // Show preview content when dragging up
                    // Smooth fade in based on drag distance
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 8)
                            .padding(.top, 0)

                        HStack(spacing: 6) {
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("Swipe up for more details")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .opacity(dragOffset < 0 ? min(abs(dragOffset) / 50, 1.0) : 0)

                    // Extended background spacer to go under tab bar
                    Color.clear
                        .frame(height: 300)
                }
            }
            .padding(.horizontal, 20)
            .background(
                // Extended background that goes under tab bar
                AppTheme.appContentBG
            )
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
            .offset(y: defaultBottomOffset + dragOffset) // Offset down by default + drag offset
            .frame(height: geometry.size.height + defaultBottomOffset, alignment: .bottom) // Extend frame to accommodate offset
            .clipped() // Clip the extended content below
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Allow both up and down drags
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let swipeDistance = value.translation.height
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if swipeDistance < -100 {
                                // Swipe up -> show full-screen profile
                                dragOffset = 0
                                showFullScreenProfile = true
                            } else if swipeDistance > 100 {
                                // Swipe down -> dismiss
                                onDismiss()
                            } else {
                                // Not enough swipe -> return to position
                                dragOffset = 0
                            }
                        }
                    }
                )
            }
        }
        .ignoresSafeArea(edges: .bottom) // Allow sheet to extend under tab bar
        .onChange(of: gym.id) { _ in
            // Reset when gym changes
            showFullScreenProfile = false
        }
        .sheet(isPresented: $showFullScreenProfile) {
            NavigationStack {
                GymProfileView(
                    gym: gym,
                    gymsViewModel: viewModel,
                    appState: viewModel.currentAppState,
                    enableRefresh: false
                )
            }
            .presentationDetents([.fraction(0.95)])
            .presentationDragIndicator(.visible)
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
        onDismiss: {},
        onVisit: { _ in },
        viewModel: GymsViewModel(appState: AppState())
    )
}
