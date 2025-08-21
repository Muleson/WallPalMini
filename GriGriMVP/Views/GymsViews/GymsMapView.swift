//
//  GymsMapView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 04/08/2025.
//

import SwiftUI
import MapKit

struct GymsMapView: View {
    @ObservedObject var viewModel: GymsViewModel
    @ObservedObject private var locationService = LocationService.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedGym: Gym?
    @State private var showingGymProfile = false
    @State private var isStandardMapStyle = true
    @State private var dragOffset: CGFloat = 0
    @State private var showingVisitOptions = false
    @State private var gymToVisit: Gym?
    @State private var navigateToGymProfile = false
    @Environment(\.dismiss) private var dismiss
    
    var allGyms: [Gym] {
        viewModel.favoriteGyms + viewModel.nonFavoriteGymsByDistance
    }
    
    var body: some View {
        ZStack {
            // Main Map
            Map(coordinateRegion: $mapRegion,
                showsUserLocation: true,
                userTrackingMode: .none,
                annotationItems: allGyms) { gym in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: gym.location.latitude,
                    longitude: gym.location.longitude
                )) {
                    GymMapAnnotationView(
                        gym: gym,
                        isFavorite: viewModel.isGymFavorited(gym),
                        isSelected: selectedGym?.id == gym.id
                    ) {
                        selectedGym = gym
                    }
                }
            }
            .mapStyle(isStandardMapStyle ? .standard : .hybrid)
            
            // Top Controls
            VStack {
                topControlsView
                Spacer()
            }
            
            // Bottom Sheet for Selected Gym
            if let selectedGym = selectedGym {
                bottomSheetView(for: selectedGym)
            }
        }
        .navigationTitle("Gyms Map")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            setupMapRegion()
        }
        .onReceive(locationService.$cachedLocation) { cachedLocation in
            if let location = cachedLocation {
                updateMapRegion(to: location)
            }
        }
        .navigationDestination(isPresented: $navigateToGymProfile) {
            if let gym = gymToVisit {
                GymProfileView(gym: gym)
            }
        }
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
    }
    
    // MARK: - Top Controls
    
    private var topControlsView: some View {
        HStack {
            // Map Style Toggle
            mapStyleToggle
            
            Spacer()
            
            // Center on User Location Button
            centerLocationButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var mapStyleToggle: some View {
        Menu {
            Button(action: { isStandardMapStyle = true }) {
                Label("Standard", systemImage: isStandardMapStyle ? "checkmark" : "")
            }
            
            Button(action: { isStandardMapStyle = false }) {
                Label("Satellite", systemImage: !isStandardMapStyle ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "map")
                .font(.title2)
                .foregroundColor(AppTheme.appPrimary)
                .frame(width: 44, height: 44)
                .background(AppTheme.appContentBG)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }
    
    private var centerLocationButton: some View {
        Button(action: centerMapOnUserLocation) {
            Image(systemName: getCenterLocationIcon())
                .font(.title2)
                .foregroundColor(getCenterLocationColor())
                .frame(width: 44, height: 44)
                .background(AppTheme.appContentBG)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
        .disabled(!locationService.hasCachedLocation && locationService.isLoading)
    }
    
// MARK: - Bottom Sheet

private func bottomSheetView(for gym: Gym) -> some View {
    VStack {
        Spacer() // Pushes the sheet to the bottom
        
        VStack(spacing: 0) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // 24px spacing from top to gym info
            gymInfoSection(for: gym)
                .padding(.top, 24)
            
            // 16px spacing from gym info to climbing types
            climbingTypesSection(for: gym)
                .padding(.top, 12)
            
            // 16px spacing from climbing types to action buttons
            actionButtons(for: gym)
                .padding(.top, 24)
                .padding(.bottom, 16) // 16px from buttons to bottom
        }
        .padding(.horizontal, 20)
        .frame(height: 300)
        .background(.white)
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
                            selectedGym = nil
                        }
                        dragOffset = 0
                    }
                }
            )
    }
    .clipped()
  //  .zIndex(1)
}

// MARK: - Component Sections (Updated for Precise Spacing)

private func gymInfoSection(for gym: Gym) -> some View {
    HStack(spacing: 8) {
        if let profileImage = gym.profileImage {
            AsyncImage(url: profileImage.url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } placeholder: {
                gymImagePlaceholder(size: 80)
            }
        } else {
            gymImagePlaceholder(size: 80)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text(gym.name)
                .font(.appHeadline)
                .foregroundColor(AppTheme.appTextPrimary)
                .multilineTextAlignment(.leading)
            
            if let distance = viewModel.distanceToGym(gym) {
                Text(distance)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        Spacer()
    }
}

    private func climbingTypesSection(for gym: Gym) -> some View {
        HStack(spacing: 32) {
            Spacer()
            
            ForEach(gym.climbingType, id: \.self) { type in
                VStack(spacing: 4) {
                    climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 54, height: 54)
                        .foregroundColor(AppTheme.appPrimary)
                    
                    Text(formatClimbingType(type))
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
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
        
 private func actionButtons(for gym: Gym) -> some View {
    HStack(spacing: 12) {
        // Favorite button
        PrimaryActionButton.toggle(
            viewModel.isGymFavorited(gym) ? "Favourited" : "Favourite",
            isEngaged: viewModel.isGymFavorited(gym)
        ) {
            Task {
                await viewModel.toggleFavoriteGym(gym)
            }
        }
        
        // Visit button
        PrimaryActionButton.primary("Visit") {
            gymToVisit = gym
            showingVisitOptions = true
        }
    }
}
    
    // MARK: - Helper Methods
    
    private func setupMapRegion() {
        // Try to use cached location first
        if let cachedLocation = locationService.getCachedLocation() {
            updateMapRegion(to: cachedLocation)
        } else {
            // Request location refresh if no cache available
            Task {
                do {
                    try await locationService.refreshLocationCache()
                    // Location will be updated via observer
                } catch {
                    print("Failed to refresh location cache on map appear: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func centerMapOnUserLocation() {
        // Try cached location first
        if let cachedLocation = locationService.getCachedLocation() {
            updateMapRegion(to: cachedLocation)
            return
        }
        
        // If no cache, request a refresh
        Task {
            do {
                try await locationService.refreshLocationCache()
                // Location will be updated via observer
            } catch {
                print("Failed to center map on user location: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateMapRegion(to location: CLLocation) {
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    private func getCenterLocationIcon() -> String {
        if locationService.isLoading {
            return "location.slash"
        } else if locationService.hasCachedLocation {
            return "location.fill"
        } else {
            return "location"
        }
    }
    
    private func getCenterLocationColor() -> Color {
        if locationService.isLoading {
            return .gray
        } else if locationService.hasCachedLocation {
            return AppTheme.appPrimary
        } else {
            return .orange
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
    NavigationStack {
        GymsMapView(viewModel: GymsViewModel(appState: AppState()))
    }
}
