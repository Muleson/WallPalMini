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
    @State private var showingVisitOptions = false
    @State private var gymToVisit: Gym?
    @State private var hasFocusedOnGym = false
    @State private var userHasManuallyPanned = false
    @State private var shouldHideNearbyPins = false
    @Environment(\.dismiss) private var dismiss

    // Radius for "nearby" pins in degrees (approximately 1km)
    private let nearbyRadius: Double = 0.01
    
    // Optional parameter to focus on a specific gym
    let selectedGymId: String?
    
    init(viewModel: GymsViewModel, selectedGymId: String? = nil) {
        self.viewModel = viewModel
        self.selectedGymId = selectedGymId
    }
    
    var allGyms: [Gym] {
        var gyms = viewModel.favoriteGyms + viewModel.nonFavoriteGymsByDistance

        // Filter out nearby pins when focus mode is active
        if let selectedGym = selectedGym, shouldHideNearbyPins {
            gyms = gyms.filter { gym in
                // Keep the selected gym
                if gym.id == selectedGym.id {
                    return true
                }
                // Hide nearby gyms
                return !isGymNearSelected(gym, selected: selectedGym)
            }
        }

        // Move selected gym to the end of the array to ensure it renders on top
        if let selectedGym = selectedGym,
           let index = gyms.firstIndex(where: { $0.id == selectedGym.id }) {
            let gym = gyms.remove(at: index)
            gyms.append(gym)
        }

        return gyms
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
                        viewModel: viewModel,
                        isSelected: selectedGym?.id == gym.id
                    ) {
                        selectedGym = gym
                        // Enable focus mode to hide nearby pins
                        withAnimation(.easeInOut(duration: 0.3)) {
                            shouldHideNearbyPins = true
                        }
                    }
                }
            }
            .mapStyle(isStandardMapStyle ? .standard : .hybrid)
            .onMapCameraChange { _ in
                // User is interacting with map - restore all pins
                if shouldHideNearbyPins {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        shouldHideNearbyPins = false
                    }
                }
            }

            // Top Controls
            VStack {
                topControlsView
                Spacer()
            }
            
            // Bottom Sheet for Selected Gym
            if let selectedGym = selectedGym {
                MapBottomSheet(
                    gym: selectedGym,
                    viewModel: viewModel,
                    onDismiss: {
                        self.selectedGym = nil
                        // Reset all flags when user manually deselects
                        hasFocusedOnGym = false
                        userHasManuallyPanned = false
                        withAnimation(.easeInOut(duration: 0.3)) {
                            shouldHideNearbyPins = false
                        }
                    },
                    onVisit: { gym in
                        gymToVisit = gym
                        showingVisitOptions = true
                    }
                )
                .id("map-bottom-sheet-\(selectedGym.id)")
            }
        }
        .navigationTitle("Gyms Map")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // If a specific gym is selected, focus on it
            if let gymId = selectedGymId,
               let gym = allGyms.first(where: { $0.id == gymId }) {
                focusOnGym(gym)
            } else {
                // Only setup default map region if not focusing on a specific gym
                setupMapRegion()
            }
        }
        .onReceive(locationService.$cachedLocation) { cachedLocation in
            // Only update map region from location if we haven't focused on a specific gym
            // and the user hasn't manually interacted with the map
            if !hasFocusedOnGym && !userHasManuallyPanned, let location = cachedLocation {
                updateMapRegion(to: location)
            }
        }
        .onChange(of: selectedGym) { newValue in
            // Reset focus flag when gym is deselected
            if newValue == nil {
                hasFocusedOnGym = false
            }
        }
        .navigationDestination(isPresented: $showingGymProfile) {
            if let gym = gymToVisit {
                GymProfileView(gym: gym, appState: viewModel.currentAppState)
                    .onDisappear {
                        // Reset navigation state when leaving gym profile
                        gymToVisit = nil
                        showingGymProfile = false
                    }
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
                showingGymProfile = true
                showingVisitOptions = false
                // Don't set gymToVisit to nil here - it's needed for navigation
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

    // MARK: - Helper Methods

    private func isGymNearSelected(_ gym: Gym, selected: Gym) -> Bool {
        let latDiff = abs(gym.location.latitude - selected.location.latitude)
        let lonDiff = abs(gym.location.longitude - selected.location.longitude)
        let distance = sqrt(latDiff * latDiff + lonDiff * lonDiff)
        return distance < nearbyRadius
    }

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
        // Reset flags to allow centering on user
        hasFocusedOnGym = false
        userHasManuallyPanned = false

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
    
    private func focusOnGym(_ gym: Gym) {
        // Mark that we've focused on a gym to prevent location updates from overriding
        hasFocusedOnGym = true
        
        // Center map on the gym
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: gym.location.latitude,
                    longitude: gym.location.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // Closer zoom
            )
        }
        // Select the gym to show its bottom sheet
        selectedGym = gym
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
}

#Preview {
    NavigationStack {
        GymsMapView(viewModel: GymsViewModel(appState: AppState()), selectedGymId: nil)
    }
}
