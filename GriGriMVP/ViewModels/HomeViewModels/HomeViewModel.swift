//
//  HomeViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import CoreLocation
import Combine
@preconcurrency import EventKit

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Content Properties
    @Published var allEvents: [EventItem] = []
    @Published var featuredEvent: EventItem? // Single featured event for "Up next"
    @Published var upcomingEvents: [EventItem] = [] // Remaining events for "Coming Up"
    
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
    
    // Event filtering configuration
    private let allowedEventTypes: Set<EventType> = [.competition, .opening, .settingTaster, .openDay]
    private let totalEventsToLoad = 5
    private let featuredEventTimeWindow: TimeInterval = 14 * 24 * 60 * 60 // 14 days in seconds
    
    // Services and repositories
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    private let passManager = PassManager.shared
    
    // Current user data
    private var currentUser: User?
    @Published private(set) var favoritedEventIds: Set<String> = []
    
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
        // NOTE: Events will be loaded on-demand when HomeView appears
        // This eliminates upfront database calls on app launch

        // Check for existing cached location
        checkCachedLocation()

        print("🏠 HomeViewModel: Initialized (0 events loaded)")
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
        
        // Observe pass changes to update nearest gym
        passManager.$passes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When passes change, update the nearest gym calculation
                if self?.userLocation != nil {
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

    /// Load home carousel events on-demand (called by HomeView.onAppear)
    func loadHomeEvents() {
        guard !isLoadingEvents && allEvents.isEmpty else {
            return
        }

        isLoadingEvents = true

        Task {
            do {
                let events = try await fetchBatchEventsForHome()
                allEvents = events
                processEventsForHome()
                isLoadingEvents = false
            } catch {
                isLoadingEvents = false
                errorMessage = "Failed to load events: \(error.localizedDescription)"
                hasError = true
            }
        }
    }
    
    /// Optimized batch loading for home view - loads only carousel events with server-side filters
    private func fetchBatchEventsForHome() async throws -> [EventItem] {
        let currentDate = Date()
        let featuredDeadline = currentDate.addingTimeInterval(featuredEventTimeWindow)

        // Use new filtered query instead of loading ALL events
        let events = try await eventRepository.fetchEventsWithFilters(
            eventTypes: allowedEventTypes,
            startDateAfter: currentDate,
            startDateBefore: nil,
            isFeatured: nil,
            hostGymId: nil,
            limit: 20
        )

        // Filter for events with media
        let eventsWithMedia = events.filter { event in
            !(event.mediaItems?.isEmpty ?? true)
        }

        // Separate featured and non-featured events
        let featuredCandidates = eventsWithMedia.filter { event in
            event.startDate > currentDate && event.startDate <= featuredDeadline
        }

        let nonFeaturedEvents = eventsWithMedia.filter { event in
            event.startDate > featuredDeadline
        }

        // Combine featured events first, then non-featured, sorted by date
        let combinedEvents = Array((featuredCandidates + nonFeaturedEvents)
            .sorted(by: { $0.startDate < $1.startDate })
            .prefix(totalEventsToLoad))
        
        return combinedEvents
    }
    
    /// Process the loaded events to determine featured event and upcoming events
    private func processEventsForHome() {
        guard !allEvents.isEmpty else {
            featuredEvent = nil
            upcomingEvents = []
            return
        }
        
        let currentDate = Date()
        let featuredDeadline = currentDate.addingTimeInterval(featuredEventTimeWindow)
        
        // Find featured events within the time window
        let featuredCandidates = allEvents.filter { event in
            event.isFeatured == true &&
            event.startDate > currentDate &&
            event.startDate <= featuredDeadline
        }
        
        // Set the featured event (closest upcoming featured event)
        if let nearestFeatured = featuredCandidates.min(by: { $0.startDate < $1.startDate }) {
            featuredEvent = nearestFeatured
            // Remove featured event from remaining events
            upcomingEvents = allEvents.filter { $0.id != nearestFeatured.id }
        } else {
            // No featured events within window, use the nearest upcoming event
            if let nearestEvent = allEvents.min(by: { $0.startDate < $1.startDate }) {
                featuredEvent = nearestEvent
                upcomingEvents = allEvents.filter { $0.id != nearestEvent.id }
            } else {
                featuredEvent = nil
                upcomingEvents = allEvents
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
    
    // MARK: - Nearest Gym Logic
    
    func findNearestGym() {
        guard let userLocation = userLocation else { return }
        
        isLoadingGyms = true
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let gyms = try await gymRepository.fetchAllGyms()
                
                // Capture passes on main thread before filtering
                let currentPasses = await MainActor.run {
                    return passManager.passes
                }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    allGyms = gyms
                }
                
                // Filter gyms to only include those with passes
                let gymsWithPasses = gyms.filter { gym in
                    currentPasses.contains { pass in
                        pass.gymId == gym.id
                    }
                }
                
                // Find the nearest gym that has a pass
                let nearestGym = gymsWithPasses.min { gym1, gym2 in
                    let distance1 = locationService.distance(from: userLocation, to: gym1.location)
                    let distance2 = locationService.distance(from: userLocation, to: gym2.location)
                    return distance1 < distance2
                }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.nearestGym = nearestGym
                    isLoadingGyms = false
                }
                
            } catch {
                print("Failed to fetch gyms: \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    isLoadingGyms = false
                }
            }
        }
    }
    
    // MARK: - Pass Management
    
    /// Sets the active pass for the given gym and returns true if successful
    func setActivePassForGym(_ gym: Gym) -> Bool {
        guard let pass = passManager.passes.first(where: { $0.gymId == gym.id }) else {
            return false
        }
        
        passManager.setActivePass(id: pass.id)
        return true
    }
    
    /// Returns the pass associated with the given gym, if any
    func passForGym(_ gym: Gym) -> Pass? {
        return passManager.passes.first(where: { $0.gymId == gym.id })
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
                }
            } catch {
                errorMessage = "Failed to update favorite: \(error.localizedDescription)"
                hasError = true
            }
        }
    }
    
    // MARK: - Filtering Logic
    
    func applyFilters() {
        // With batch loading, filtering is minimal since we only load what we need
        // Just ensure we have processed events properly and find nearest gym if needed
        processEventsForHome()
        
        // Find nearest gym when applying filters if location available and no gym found
        if userLocation != nil && nearestGym == nil {
            findNearestGym()
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
        loadHomeEvents()
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
        return event.registrationRequired
    }
}
