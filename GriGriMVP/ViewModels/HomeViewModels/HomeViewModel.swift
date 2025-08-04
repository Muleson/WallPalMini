//
//  HomeViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import CoreLocation
import Combine
import EventKit

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Content Properties
    @Published var allEvents: [EventItem] = []
    @Published var featuredEvents: [EventItem] = []
    @Published var nearbyEvents: [EventItem] = []
    
    // Nearest gym functionality for redesigned home
    @Published var nearestGym: Gym?
    @Published var allGyms: [Gym] = []
    
    // MARK: - State Properties
    @Published var isLoadingEvents = false
    @Published var isLoadingGyms = false
    @Published var isLocationLoading = false
    
    // Error handling
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Location services
    @Published var userLocation: CLLocation?
    @Published var locationPermissionGranted = false
    
    // MARK: - Private Properties
    private let maxDistanceInMeters: Double = 10000
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Services and repositories
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    
    // Current user data
    private var currentUser: User?
    private var favoritedEventIds: Set<String> = []
    
    // MARK: - Computed Properties
    
    /// Distance to nearest gym formatted for display
    var distanceToNearestGym: String? {
        guard let nearestGym = nearestGym,
              let userLocation = userLocation else { return nil }
        
        let distance = locationService.distance(from: userLocation, to: nearestGym.location)
        
        if distance < 1000 {
            return String(format: "%.0fm away", distance)
        } else if distance < 10000 {
            return String(format: "%.1fkm away", distance / 1000)
        } else {
            return String(format: "%.0fkm away", distance / 1000)
        }
    }
    
    // MARK: - Initialization
    
    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         eventRepository: EventRepositoryProtocol? = nil) {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        self.eventRepository = eventRepository ?? RepositoryFactory.createEventRepository()

        setupLocationObservers()
        fetchUserAndFavorites()
        fetchEvents()
        
        // Check for existing cached location
        checkCachedLocation()
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
        
        // Observe cached location changes
        locationService.$cachedLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cachedLocation in
                if let location = cachedLocation {
                    self?.userLocation = location
                    self?.applyFilters()
                    self?.findNearestGym()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationPermissionStatus(_ status: CLAuthorizationStatus) {
        locationPermissionGranted = status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    /// Check for cached location on initialization
    private func checkCachedLocation() {
        if let cachedLocation = locationService.getCachedLocation() {
            userLocation = cachedLocation
            applyFilters()
            findNearestGym()
        }
    }
    
    /// Manual refresh for pull-to-refresh
    func refreshLocation() {
        Task {
            do {
                try await locationService.refreshLocationCache()
                // Location will be updated via observer
            } catch {
                handleLocationError(error.localizedDescription)
            }
        }
    }
    
    private func handleLocationError(_ error: String) {
        // Only show location errors if they're not permission-related
        if !error.contains("denied") && !error.contains("permission") {
            errorMessage = error
            hasError = true
        }
    }
    
    func openLocationSettings() {
        locationService.openLocationSettings()
    }
    
    // MARK: - Data Fetching
    
    func fetchEvents() {
        isLoadingEvents = true
        
        Task {
            do {
                let events = try await eventRepository.fetchAllEvents()
                
                allEvents = events
                isLoadingEvents = false
                applyFilters()
                
            } catch {
                errorMessage = "Failed to load events: \(error.localizedDescription)"
                hasError = true
                isLoadingEvents = false
            }
        }
    }
    
    func fetchUserAndFavorites() {
        Task {
            do {
                if let user = try await userRepository.getCurrentUser() {
                    currentUser = user
                    favoritedEventIds = Set(user.favoriteEvents ?? [])
                    updateFavoriteEvents()
                }
            } catch {
                errorMessage = "Failed to load user data: \(error.localizedDescription)"
                hasError = true
            }
        }
    }
    
    func findNearestGym() {
        guard let userLocation = userLocation else { return }
        
        isLoadingGyms = true
        
        Task {
            do {
                let gyms = try await gymRepository.fetchAllGyms()
                allGyms = gyms
                
                // Find the nearest gym
                let nearestGym = gyms.min { gym1, gym2 in
                    let distance1 = locationService.distance(from: userLocation, to: gym1.location)
                    let distance2 = locationService.distance(from: userLocation, to: gym2.location)
                    return distance1 < distance2
                }
                
                self.nearestGym = nearestGym
                isLoadingGyms = false
                
            } catch {
                print("Failed to fetch gyms: \(error.localizedDescription)")
                isLoadingGyms = false
            }
        }
    }
    
    // MARK: - User Favorites Management
    
    private func updateFavoriteEvents() {
        applyFilters()
    }
    
    func isEventFavorited(_ event: EventItem) -> Bool {
        return favoritedEventIds.contains(event.id)
    }
    
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
                errorMessage = "Failed to update favorite: \(error.localizedDescription)"
                hasError = true
            }
        }
    }
    
    // MARK: - Filtering Logic
    
    func applyFilters() {
        filterFeaturedEvents()
        filterNearbyEvents()
        
        // Find nearest gym when applying filters if location available and no gym found
        if userLocation != nil && nearestGym == nil {
            findNearestGym()
        }
    }
    
    private func filterFeaturedEvents() {
        // Filter for featured events (events marked as featured by the system)
        featuredEvents = allEvents.filter { $0.isFeatured == true }
        
        // If no featured events, use most upcoming events as featured
        if featuredEvents.isEmpty {
            let upcomingEvents = allEvents.filter { $0.startDate > Date() }
                .sorted(by: { $0.startDate < $1.startDate })
            featuredEvents = Array(upcomingEvents.prefix(3))
        }
    }
    
    private func filterNearbyEvents() {
        // Get upcoming events only
        let upcomingEvents = allEvents.filter { $0.startDate > Date() }
        
        guard !upcomingEvents.isEmpty else {
            nearbyEvents = []
            return
        }
        
        // If no location, just show upcoming events sorted by date
        guard userLocation != nil else {
            nearbyEvents = Array(upcomingEvents
                .sorted(by: { $0.startDate < $1.startDate })
                .prefix(10))
            return
        }
        
        // Use cache-based filtering from LocationService
        do {
            let locationExtractor: (EventItem) -> LocationData = { event in
                return event.host.location
            }
            
            // Filter events by distance using cached location
            let filteredEvents = try locationService.filterEventsByDistance(
                upcomingEvents,
                maxDistance: maxDistanceInMeters,
                locationExtractor: locationExtractor
            )
            
            // Sort by proximity using cached location
            let sortedEvents = try locationService.sortEventsByProximity(
                filteredEvents,
                locationExtractor: locationExtractor
            )
            
            // Limit number of results
            nearbyEvents = Array(sortedEvents.prefix(10))
            
        } catch LocationError.cacheExpired {
            // Cache expired, show events sorted by date
            nearbyEvents = Array(upcomingEvents
                .sorted(by: { $0.startDate < $1.startDate })
                .prefix(10))
        } catch {
            print("Error filtering nearby events: \(error)")
            nearbyEvents = Array(upcomingEvents
                .sorted(by: { $0.startDate < $1.startDate })
                .prefix(10))
        }
    }
    
    // MARK: - Utility Methods
    
    func distanceToEvent(_ event: EventItem) -> Double? {
        guard userLocation != nil else { return nil }
        
        do {
            return try locationService.distanceToEvent(
                event,
                locationExtractor: { $0.host.location }
            )
        } catch {
            return nil
        }
    }
    
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
    
    // MARK: - Public Refresh Method
    
    func refresh() {
        fetchUserAndFavorites()
        fetchEvents()
        refreshLocation()
    }
    
    // MARK: - Calendar Management
    
    /// Add event to device calendar
    func addEventToCalendar(_ event: EventItem) {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted && error == nil {
                    self?.createCalendarEvent(event, in: eventStore)
                } else {
                    self?.errorMessage = "Calendar access denied. Please enable in Settings."
                    self?.hasError = true
                }
            }
        }
    }
    
    private func createCalendarEvent(_ event: EventItem, in eventStore: EKEventStore) {
        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = event.name
        calendarEvent.startDate = event.startDate
        calendarEvent.endDate = event.endDate
        calendarEvent.location = "\(event.host.name), \(event.host.location.address)"
        calendarEvent.notes = event.description
        calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(calendarEvent, span: .thisEvent)
            // Could add success feedback here
        } catch {
            errorMessage = "Failed to add event to calendar: \(error.localizedDescription)"
            hasError = true
        }
    }
    
    /// Check if an event requires registration
    func requiresRegistration(_ event: EventItem) -> Bool {
        return event.registrationRequired ?? true // Default to true if not specified
    }
}
