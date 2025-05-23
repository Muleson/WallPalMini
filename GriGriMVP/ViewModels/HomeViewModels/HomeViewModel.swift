//
//  HomeViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import CoreLocation
import Combine

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
    
    // Location services
    @Published var userLocation: CLLocation?
    private let maxDistanceInMeters: Double = 10000
    private let locationManager = CLLocationManager()
    
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
        setupLocationManager()
        fetchUserAndFavorites()
        fetchEvents()
    }
    
    // Fetches user location for filtering event feed
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Get initial location if available
        if let location = locationManager.location {
            self.userLocation = location
        }
    }
    
    // MARK: - User and Favorites
    
    func fetchUserAndFavorites() {
        Task {
            do {
                if let user = try await userRepository.getCurrentUser() {
                    await MainActor.run {
                        self.currentUser = user
                        self.favoritedEventIds = Set(user.favoriteEvents ?? [])
                        self.updateFavoriteEvents()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    self.hasError = true
                }
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
                    await MainActor.run {
                        if isCurrentlyFavorite {
                            favoritedEventIds.remove(event.id)
                        } else {
                            favoritedEventIds.insert(event.id)
                        }
                        updateFavoriteEvents()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update favorite: \(error.localizedDescription)"
                    self.hasError = true
                }
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
    func filterFeaturedEvents() {
        // Filter for featured events (events marked as featured by the system)
        // For now, we'll just use a simple approach for demo purposes
        featuredEvents = allEvents.filter { $0.isFeatured == true }
        
        // If no featured events, use most upcoming events as featured
        if featuredEvents.isEmpty {
            let upcomingEvents = allEvents.filter { $0.eventDate > Date() }
            featuredEvents = Array(upcomingEvents.prefix(3))
        }
    }
    
    // Filters events by user favourites
    func filterFavoriteGymEvents() {
        // Filter featured events - typically events marked as featured by the system
        // For demo, we'll just use the first 3 events
        self.featuredEvents = Array(allEvents.prefix(3))
        
        // Filter events from user's favorite gyms
        if let favoriteGymIds = currentUser?.favoriteGyms {
            self.favoriteGymEvents = allEvents.filter { event in
                return favoriteGymIds.contains(event.host.id)
            }
        } else {
            favoriteGymEvents = []
        }
    }
    
    // Filters events by user Location
    func filterNearbyEvents() {
        /// Get upcoming events only
        let upcomingEvents = allEvents.filter { $0.eventDate > Date() }
        
        if let userLocation = userLocation, !upcomingEvents.isEmpty {
            let locationService = LocationService.shared
            
            /// Extract location data from an event
            let locationExtractor: (EventItem) -> LocationData = { event in
                return event.host.location
            }
            
            /// Filter events by distance
            let filteredEvents = locationService.filterEventsByDistance(
                upcomingEvents,
                from: userLocation,
                maxDistance: maxDistanceInMeters,
                locationExtractor: locationExtractor
            )
            
            /// Sort by proximity
            nearbyEvents = locationService.sortEventsByProximity(
                filteredEvents,
                to: userLocation,
                locationExtractor: locationExtractor
            )
            
            /// Limit number of results
            if nearbyEvents.count > 10 {
                nearbyEvents = Array(nearbyEvents.prefix(10))
            }
        } else {
            /// No location or no events, sort by date
            nearbyEvents = upcomingEvents
                .sorted(by: { $0.eventDate < $1.eventDate })
                .prefix(5)
                .map { $0 }
        }
    }
    
    // Fetches instances of events relevent for user
    func fetchEvents() {
        isLoadingEvents = true
        
        Task {
            do {
                let events = try await eventRepository.fetchAllEvents()
                await MainActor.run {
                    self.allEvents = events
                    self.isLoadingEvents = false
                    self.applyFilters()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                    self.hasError = true
                    self.isLoadingEvents = false
                }
            }
        }
    }
}
