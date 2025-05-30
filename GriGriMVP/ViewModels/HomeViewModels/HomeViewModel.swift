//
//  HomeViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // Content items
    @Published var allEvents: [EventItem] = []
    @Published var featuredEvents: [EventItem] = []
    @Published var favoriteGymEvents: [EventItem] = []
    @Published var nearbyEvents: [EventItem] = []
    @Published var userFavoriteEvents: [EventItem] = []
    
    // Error handling
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Loading states
    @Published var isLoadingEvents = false
    @Published var isLoading = false
    @Published var isLocationLoading = false
    
    // Location services
    @Published var userLocation: CLLocation?
    @Published var locationPermissionGranted = false
    @Published var canRequestLocation = true
    
    private let maxDistanceInMeters: Double = 10000
    private let locationService = LocationService.shared
    
    // Services and repositories
    private var cancellables = Set<AnyCancellable>()
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    
    // Current user data
    private var currentUser: User?
    private var favoritedEventIds: Set<String> = []
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         gymRepository: GymRepositoryProtocol = FirebaseGymRepository(),
         eventRepository: EventRepositoryProtocol? = nil) {
        self.userRepository = userRepository
        self.eventRepository = eventRepository ?? FirebaseEventRepository(
            userRepository: userRepository,
            gymRepository: gymRepository
        )
        
        setupLocationObservers()
        fetchUserAndFavorites()
        fetchEvents()
        requestLocationIfNeeded()
    }
    
    // MARK: - Location Management
    
    private func setupLocationObservers() {
        // Observe location service authorization changes
        locationService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateLocationPermissionStatus(status)
            }
            .store(in: &cancellables)
        
        // Observe location service loading state
        locationService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLocationLoading, on: self)
            .store(in: &cancellables)
        
        // Observe location service errors
        locationService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.handleLocationError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationPermissionStatus(_ status: CLAuthorizationStatus) {
        locationPermissionGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        canRequestLocation = status != .denied && status != .restricted
        
        // If permission was just granted, try to get location
        if locationPermissionGranted && userLocation == nil {
            requestUserLocation()
        }
    }
    
    private func requestLocationIfNeeded() {
        // Only request location if we have permission or it's not determined yet
        if locationService.authorizationStatus == .authorizedWhenInUse || 
           locationService.authorizationStatus == .authorizedAlways {
            requestUserLocation()
        } else if locationService.authorizationStatus == .notDetermined {
            // Will be handled automatically by LocationService when permission is requested
        }
    }
    
    func requestUserLocation() {
        guard canRequestLocation else {
            errorMessage = "Location access is not available. Please check your settings."
            hasError = true
            return
        }
        
        Task {
            do {
                let location = try await locationService.requestCurrentLocation()
                
                self.userLocation = location
                self.errorMessage = nil
                self.hasError = false
                
                // Re-filter events with new location
                self.applyFilters()
                
            } catch {
                if let locationError = error as? LocationError {
                    switch locationError {
                    case .permissionDenied:
                        self.locationPermissionGranted = false
                        self.canRequestLocation = false
                        // Don't show error for permission denied - let UI handle this gracefully
                        break
                    case .servicesDisabled:
                        self.errorMessage = "Location services are disabled. Enable them in Settings to see nearby events."
                        self.hasError = true
                    case .timeout:
                        self.errorMessage = "Location request timed out. Please try again."
                        self.hasError = true
                    default:
                        self.errorMessage = locationError.localizedDescription
                        self.hasError = true
                    }
                } else {
                    self.errorMessage = "Failed to get location: \(error.localizedDescription)"
                    self.hasError = true
                }
            }
        }
    }
    
    private func handleLocationError(_ error: String) {
        // Only show location errors if they're not permission-related
        // (Permission errors should be handled by UI prompts, not error messages)
        if !error.contains("denied") && !error.contains("permission") {
            errorMessage = error
            hasError = true
        }
    }
    
    func openLocationSettings() {
        locationService.openLocationSettings()
    }
    
    // MARK: - User and Favorites
    
    func fetchUserAndFavorites() {
        Task {
            do {
                if let user = try await userRepository.getCurrentUser() {
                    self.currentUser = user
                    self.favoritedEventIds = Set(user.favoriteEvents ?? [])
                    self.updateFavoriteEvents()
                }
            } catch {
                self.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                self.hasError = true
            }
        }
    }
    
    private func updateFavoriteEvents() {
        // Update the favorites collection based on IDs
        self.userFavoriteEvents = self.allEvents.filter {
            favoritedEventIds.contains($0.id)
        }
        
        // Also update other filters that might depend on favorites
        self.applyFilters()
    }
    
    // Check if an event is favorited
    func isEventFavorited(_ event: EventItem) -> Bool {
        return favoritedEventIds.contains(event.id)
    }
    
    // Toggle favorite status
    func toggleFavorite(for event: EventItem) {
        Task {
            do {
                if let userId = userRepository.getCurrentAuthUser() {
                    let isCurrentlyFavorite = isEventFavorited(event)
                    
                    // Update in repository
                    _ = try await userRepository.updateUserFavoriteEvents(
                        userId: userId,
                        eventId: event.id,
                        isFavorite: !isCurrentlyFavorite
                    )
                    
                    // Update local state
                    if isCurrentlyFavorite {
                        favoritedEventIds.remove(event.id)
                    } else {
                        favoritedEventIds.insert(event.id)
                    }
                    updateFavoriteEvents()
                }
            } catch {
                self.errorMessage = "Failed to update favorite: \(error.localizedDescription)"
                self.hasError = true
            }
        }
    }
    
    // MARK: - Filter Methods
    
    func applyFilters() {
        filterFeaturedEvents()
        filterFavoriteGymEvents()
        filterNearbyEvents()
    }
    
    // Filters events by featured status
    private func filterFeaturedEvents() {
        // Filter for featured events (events marked as featured by the system)
        featuredEvents = allEvents.filter { $0.isFeatured == true }
        
        // If no featured events, use most upcoming events as featured
        if featuredEvents.isEmpty {
            let upcomingEvents = allEvents.filter { $0.eventDate > Date() }
                .sorted(by: { $0.eventDate < $1.eventDate })
            featuredEvents = Array(upcomingEvents.prefix(3))
        }
    }
    
    // Filters events by user favorite gyms
    private func filterFavoriteGymEvents() {
        // Filter events from user's favorite gyms
        if let favoriteGymIds = currentUser?.favoriteGyms {
            self.favoriteGymEvents = allEvents.filter { event in
                return favoriteGymIds.contains(event.host.id)
            }
        } else {
            favoriteGymEvents = []
        }
    }
    
    // Filters events by user location
    private func filterNearbyEvents() {
        // Get upcoming events only
        let upcomingEvents = allEvents.filter { $0.eventDate > Date() }
        
        guard let userLocation = userLocation, !upcomingEvents.isEmpty else {
            // No location or no events, sort by date
            nearbyEvents = upcomingEvents
                .sorted(by: { $0.eventDate < $1.eventDate })
                .prefix(5)
                .map { $0 }
            return
        }
        
        // Extract location data from an event
        let locationExtractor: (EventItem) -> LocationData = { event in
            return event.host.location
        }
        
        // Filter events by distance using LocationService
        let filteredEvents = locationService.filterEventsByDistance(
            upcomingEvents,
            from: userLocation,
            maxDistance: maxDistanceInMeters,
            locationExtractor: locationExtractor
        )
        
        // Sort by proximity using LocationService
        let sortedEvents = locationService.sortEventsByProximity(
            filteredEvents,
            to: userLocation,
            locationExtractor: locationExtractor
        )
        
        // Limit number of results
        nearbyEvents = Array(sortedEvents.prefix(10))
    }
    
    // Get distance to a specific event (useful for UI display)
    func distanceToEvent(_ event: EventItem) -> Double? {
        guard let userLocation = userLocation else { return nil }
        
        return locationService.distanceToEvent(
            event,
            from: userLocation,
            locationExtractor: { $0.host.location }
        )
    }
    
    // Format distance for display
    func formattedDistanceToEvent(_ event: EventItem) -> String? {
        guard let distance = distanceToEvent(event) else { return nil }
        
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        
        if distance < 1000 {
            let measurement = Measurement(value: distance, unit: UnitLength.meters)
            return formatter.string(from: measurement)
        } else {
            let measurement = Measurement(value: distance / 1000, unit: UnitLength.kilometers)
            return formatter.string(from: measurement)
        }
    }
    
    // MARK: - Event Fetching
    
    func fetchEvents() {
        isLoadingEvents = true
        
        Task {
            do {
                let events = try await eventRepository.fetchAllEvents()
                
                // Debug logging for media items
                for event in events {
                    if let mediaItems = event.mediaItems, !mediaItems.isEmpty {
                        print("DEBUG: Event '\(event.name)' loaded with \(mediaItems.count) media items")
                    } else {
                        print("DEBUG: Event '\(event.name)' loaded with no media items")
                    }
                }
                
                self.allEvents = events
                self.isLoadingEvents = false
                self.applyFilters()
                
            } catch {
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                self.hasError = true
                self.isLoadingEvents = false
            }
        }
    }
    
    // Refresh all data
    func refresh() {
        fetchUserAndFavorites()
        fetchEvents()
        
        // Re-request location if we have permission but no location
        if locationPermissionGranted && userLocation == nil {
            requestUserLocation()
        }
    }
}
