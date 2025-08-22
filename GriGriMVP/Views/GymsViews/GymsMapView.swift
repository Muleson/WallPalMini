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
                MapBottomSheet(
                    gym: selectedGym,
                    viewModel: viewModel,
                    onDismiss: {
                        self.selectedGym = nil
                    },
                    onVisit: { gym in
                        gymToVisit = gym
                        showingVisitOptions = true
                    }
                )
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
}

#Preview {
    NavigationStack {
        GymsMapView(viewModel: GymsViewModel(appState: AppState()))
    }
}
