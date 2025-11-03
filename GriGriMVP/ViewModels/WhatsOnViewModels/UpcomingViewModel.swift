//
//  UpcomingViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/08/2025.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class UpcomingViewModel: ObservableObject {
    // MARK: - Content Properties
    @Published var allEvents: [EventItem] = []
    @Published var filteredEvents: [EventItem] = []
    @Published var favoriteGyms: [Gym] = []
    
    // MARK: - Section-Specific Loading
    private let upcomingSectionLoader: UpcomingSectionLoader
    
    // MARK: - Filter Properties
    @Published var selectedEventTypes: Set<EventType> = []
    @Published var selectedClimbingTypes: Set<ClimbingTypes> = []
    @Published var proximityFilter: ProximityFilter = .all
    @Published var selectedTimeframe: TimeframeFilter = .all
    @Published var showFavoriteGymsOnly = false
    @Published var searchText = ""
    
    // MARK: - State Properties
    @Published var isLoadingEvents = false
    @Published var isLoadingGyms = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Location services
    @Published var userLocation: CLLocation?
    @Published var locationPermissionGranted = false
    
    // MARK: - Filter Enums
    enum TimeframeFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case next7Days = "Next 7 Days"
        case next30Days = "Next 30 Days"
        
        var displayName: String { rawValue }
    }
    
    enum ProximityFilter: String, CaseIterable {
        case all = "all"
        case nearby = "nearby"
        case withinFiveKm = "5km"
        case withinTenKm = "10km"
        case withinTwentyKm = "20km"
        
        var displayName: String {
            switch self {
            case .all:
                return "All Locations"
            case .nearby:
                return "Nearby"
            case .withinFiveKm:
                return "Within 5 km"
            case .withinTenKm:
                return "Within 10 km"
            case .withinTwentyKm:
                return "Within 20 km"
            }
        }
        
        var distanceInMeters: Double? {
            switch self {
            case .all, .nearby:
                return nil
            case .withinFiveKm:
                return 5000
            case .withinTenKm:
                return 10000
            case .withinTwentyKm:
                return 20000
            }
        }
    }
    
    // MARK: - Private Properties
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Services and repositories
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    
    // Current user data
    private var currentUser: User?
    @Published private(set) var favoritedEventIds: Set<String> = []
    private var availableEventTypes: Set<EventType> = []
    
    // MARK: - Computed Properties
    
    /// All available event types from loaded events
    var eventTypes: [EventType] {
        Array(availableEventTypes).sorted { $0.displayName < $1.displayName }
    }
    
    /// Count of events matching current filters
    var filteredEventCount: Int {
        filteredEvents.count
    }
    
    /// Whether any filters are currently active
    var hasActiveFilters: Bool {
        !selectedEventTypes.isEmpty || 
        !selectedClimbingTypes.isEmpty ||
        proximityFilter != .all ||
        selectedTimeframe != .all || 
        showFavoriteGymsOnly || 
        !searchText.isEmpty
    }
    
    // MARK: - Section-Specific Computed Properties
    
    /// Class events optimized for horizontal scroll section
    var classEvents: [EventItem] {
        upcomingSectionLoader.sectionEvents.classes
    }
    
    /// Featured events optimized for carousel section
    var featuredCarouselEvents: [EventItem] {
        upcomingSectionLoader.sectionEvents.featuredCarousel
    }
    
    /// Social events optimized for horizontal scroll section
    var socialEvents: [EventItem] {
        upcomingSectionLoader.sectionEvents.socialEvents
    }
    
    /// Whether section-specific loading is in progress
    var isSectionLoading: Bool {
        upcomingSectionLoader.sectionEvents.isLoading
    }
    
    // MARK: - Initialization
    
    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         eventRepository: EventRepositoryProtocol? = nil) {
        let repository = eventRepository ?? RepositoryFactory.createEventRepository()
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        self.eventRepository = repository
        self.upcomingSectionLoader = UpcomingSectionLoader(eventRepository: repository)
        
        // Observe upcomingSectionLoader changes to update combined events
        // Note: Don't manually send objectWillChange - let @Published properties handle it
        upcomingSectionLoader.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAllEventsFromSections()
            }
            .store(in: &cancellables)

        setupLocationObservers()
        setupFilterObservers()
        fetchUserAndFavorites()
        // NOTE: Sections will be loaded on-demand when UpcomingEventsView appears
        // This eliminates upfront database calls on app launch
        checkCachedLocation()

        print("📅 UpcomingViewModel: Initialized (0 events loaded)")
    }
    
    // MARK: - Setup Methods
    
    private func setupLocationObservers() {
        // Observe location service authorization changes
        locationService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateLocationPermissionStatus(status)
            }
            .store(in: &cancellables)
        
        // Observe cached location changes
        locationService.$cachedLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cachedLocation in
                if let location = cachedLocation {
                    self?.userLocation = location
                    self?.applyFilters()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupFilterObservers() {
        // Observe filter changes and re-apply filters
        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                $selectedEventTypes,
                $selectedClimbingTypes,
                $proximityFilter,
                $selectedTimeframe
            ),
            Publishers.CombineLatest3(
                $showFavoriteGymsOnly,
                $searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main),
                $userLocation
            )
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    private func updateLocationPermissionStatus(_ status: CLAuthorizationStatus) {
        locationPermissionGranted = status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    private func checkCachedLocation() {
        if let cachedLocation = locationService.getCachedLocation() {
            userLocation = cachedLocation
        }
    }
    
    // MARK: - Data Fetching
    
    /// Load upcoming section events optimized for the UpcomingEventsView
    func loadUpcomingSections(forceRefresh: Bool = false) {
        upcomingSectionLoader.loadAllSections(userLocation: userLocation, forceRefresh: forceRefresh)
    }
    
    /// Refresh a specific upcoming section
    func refreshUpcomingSection(_ section: UpcomingSection) {
        upcomingSectionLoader.refreshSection(section, userLocation: userLocation)
    }
    
    /// Legacy method - still used for search functionality without filters
    /// For filtered queries, use fetchFilteredEvents() instead
    func fetchEvents() {
        isLoadingEvents = true

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Fetch events with no type filters (used for search/browse all)
                // Don't filter by date at DB level to include recurring events
                var events = try await eventRepository.fetchEventsWithFilters(
                    eventTypes: nil,
                    startDateAfter: nil, // Don't filter by date - handle recurring events client-side
                    startDateBefore: nil,
                    isFeatured: nil,
                    hostGymId: nil,
                    limit: 500 // Reasonable limit for browse all
                )

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    let currentDate = Date()

                    // Include recurring events even if original start date is in past
                    allEvents = events.filter { event in
                        // Include if it's a future event
                        if event.startDate > currentDate {
                            return true
                        }

                        // Include if it's a recurring event (even if original start date is in the past)
                        if event.frequency != nil {
                            return true
                        }

                        // Exclude past one-time events
                        return false
                    }.sorted(by: { $0.startDate < $1.startDate })

                    print("🔍 fetchEvents: Loaded \(allEvents.count) events (including recurring)")

                    // Extract event types
                    extractEventTypes()

                    isLoadingEvents = false
                    applyFilters()
                }

            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    errorMessage = "Failed to load events: \(error.localizedDescription)"
                    hasError = true
                    isLoadingEvents = false
                }
            }
        }
    }

    /// Optimized filtered events fetch - uses server-side queries to minimize database reads
    func fetchFilteredEvents() {
        isLoadingEvents = true
        print("🔍 FilteredEventsView: User has filters - \(selectedEventTypes.count) types, timeframe: \(selectedTimeframe)")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Build server-side filters
                let eventTypes = selectedEventTypes.isEmpty ? nil : selectedEventTypes
                let startDate = calculateStartDate(from: selectedTimeframe)
                let endDate = calculateEndDate(from: selectedTimeframe)

                print("🔍 FilteredEventsView: Querying Firestore with filters")

                // Fetch with server-side filters (but don't filter by startDate to include recurring events)
                // We'll filter dates client-side to properly handle recurring events
                var events = try await eventRepository.fetchEventsWithFilters(
                    eventTypes: eventTypes,
                    startDateAfter: nil, // Don't filter by date at DB level - handle recurring events client-side
                    startDateBefore: nil,
                    isFeatured: nil,
                    hostGymId: nil,
                    limit: 500 // Fetch more since we're filtering dates client-side
                )

                print("✅ FilteredEventsView: Received \(events.count) events from repository")

                // Apply date filtering client-side to handle recurring events
                let currentDate = Date()
                events = events.filter { event in
                    // Include if it's a future event within the timeframe
                    if event.startDate > currentDate {
                        // Check if within date range if specified
                        if let start = startDate, event.startDate < start {
                            return false
                        }
                        if let end = endDate, event.startDate > end {
                            return false
                        }
                        return true
                    }

                    // Include if it's a recurring event (even if original start date is past)
                    if event.frequency != nil {
                        return true
                    }

                    return false
                }

                print("🔍 Date filter: Filtered to \(events.count) events (including recurring)")

                // Apply client-side filters (proximity, climbing types, search)
                events = applyClientSideFilters(to: events)

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    allEvents = events
                    extractEventTypes()
                    isLoadingEvents = false
                    applyFilters() // Final filtering step
                    print("✅ FilteredEventsView: Displaying \(filteredEvents.count) events")
                }

            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    errorMessage = "Failed to load filtered events: \(error.localizedDescription)"
                    hasError = true
                    isLoadingEvents = false
                    print("❌ FilteredEventsView: Error - \(error)")
                }
            }
        }
    }

    // MARK: - Filter Helper Methods

    private func calculateStartDate(from timeframe: TimeframeFilter) -> Date? {
        let now = Date()
        let calendar = Calendar.current

        switch timeframe {
        case .all:
            return now // All future events
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.start
        case .next7Days:
            return now
        case .next30Days:
            return now
        }
    }

    private func calculateEndDate(from timeframe: TimeframeFilter) -> Date? {
        let now = Date()
        let calendar = Calendar.current

        switch timeframe {
        case .all:
            return nil // No end date
        case .today:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.end
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.end
        case .next7Days:
            return calendar.date(byAdding: .day, value: 7, to: now)
        case .next30Days:
            return calendar.date(byAdding: .day, value: 30, to: now)
        }
    }

    private func applyClientSideFilters(to events: [EventItem]) -> [EventItem] {
        var filtered = events

        // Proximity filter (requires user location)
        if proximityFilter != .all, let userLocation = userLocation {
            let beforeCount = filtered.count
            filtered = filtered.filter { event in
                guard let distance = distanceToEvent(event) else { return false }

                switch proximityFilter {
                case .all:
                    return true
                case .nearby:
                    return distance <= 2000
                case .withinFiveKm, .withinTenKm, .withinTwentyKm:
                    guard let maxDistance = proximityFilter.distanceInMeters else { return true }
                    return distance <= maxDistance
                }
            }
            print("🔍 Proximity filter: \(beforeCount) → \(filtered.count) events")
        }

        // Climbing types filter (array intersection)
        if !selectedClimbingTypes.isEmpty {
            let beforeCount = filtered.count
            filtered = filtered.filter { event in
                guard let eventClimbingTypes = event.climbingType else { return false }
                return !Set(eventClimbingTypes).isDisjoint(with: selectedClimbingTypes)
            }
            print("🔍 Climbing type filter: \(beforeCount) → \(filtered.count) events")
        }

        // Search text filter
        if !searchText.isEmpty {
            let beforeCount = filtered.count
            filtered = filtered.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.host.name.localizedCaseInsensitiveContains(searchText)
            }
            print("🔍 Search filter '\(searchText)': \(beforeCount) → \(filtered.count) events")
        }

        // Favorite gyms filter
        if showFavoriteGymsOnly {
            let favoriteGymIds = Set(favoriteGyms.map { $0.id })
            let beforeCount = filtered.count
            filtered = filtered.filter { favoriteGymIds.contains($0.host.id) }
            print("🔍 Favorite gyms filter: \(beforeCount) → \(filtered.count) events")
        }

        return filtered
    }

    func fetchUserAndFavorites() {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if let user = try await userRepository.getCurrentUser() {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        currentUser = user
                        favoritedEventIds = Set(user.favoriteEvents ?? [])
                    }
                    await fetchFavoriteGyms()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    hasError = true
                }
            }
        }
    }
    
    private func fetchFavoriteGyms() async {
        guard let user = currentUser,
              let favoriteGymIds = user.favoriteGyms,
              !favoriteGymIds.isEmpty else {
            favoriteGyms = []
            return
        }
        
        isLoadingGyms = true
        
        do {
            let allGyms = try await gymRepository.fetchAllGyms()
            favoriteGyms = allGyms.filter { favoriteGymIds.contains($0.id) }
            isLoadingGyms = false
            applyFilters()
        } catch {
            print("Failed to fetch favorite gyms: \(error.localizedDescription)")
            isLoadingGyms = false
        }
    }
    
    private func extractEventTypes() {
        availableEventTypes = Set(allEvents.map { $0.eventType })
    }
    
    /// Update allEvents from section events to ensure filtering works with optimized loading
    private func updateAllEventsFromSections() {
        let sectionEvents = upcomingSectionLoader.sectionEvents
        
        // Combine all section events, avoiding duplicates
        var combinedEvents: [EventItem] = []
        var eventIds: Set<String> = []
        
        // Add events from each section, checking for duplicates
        for event in sectionEvents.classes + sectionEvents.featuredCarousel + sectionEvents.socialEvents {
            if !eventIds.contains(event.id) {
                combinedEvents.append(event)
                eventIds.insert(event.id)
            }
        }
        
        // Sort by start date
        allEvents = combinedEvents.sorted { $0.startDate < $1.startDate }
        
        // Update available event types
        extractEventTypes()
        
        // Apply filters to update filtered events
        applyFilters()
    }
    
    // MARK: - Filter Management
    
    func toggleEventType(_ eventType: EventType) {
        if selectedEventTypes.contains(eventType) {
            selectedEventTypes.remove(eventType)
        } else {
            selectedEventTypes.insert(eventType)
        }
    }
    
    func toggleClimbingType(_ climbingType: ClimbingTypes) {
        if selectedClimbingTypes.contains(climbingType) {
            selectedClimbingTypes.remove(climbingType)
        } else {
            selectedClimbingTypes.insert(climbingType)
        }
    }
    
    func setProximityFilter(_ filter: ProximityFilter) {
        proximityFilter = filter
    }

    func clearAllFilters() {
        selectedEventTypes.removeAll()
        selectedClimbingTypes.removeAll()
        proximityFilter = .all
        selectedTimeframe = .all
        showFavoriteGymsOnly = false
        searchText = ""
    }
    
    func setTimeframe(_ timeframe: TimeframeFilter) {
        selectedTimeframe = timeframe
    }
    
    func toggleFavoriteGymsFilter() {
        showFavoriteGymsOnly.toggle()
    }
    
    // MARK: - Filtering Logic
    
    func applyFilters() {
        var events = allEvents
        
        // Filter by search text
        if !searchText.isEmpty {
            events = events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.host.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by event types
        if !selectedEventTypes.isEmpty {
            events = events.filter { event in
                return selectedEventTypes.contains(event.eventType)
            }
        }
        
        // Filter by climbing types
        if !selectedClimbingTypes.isEmpty {
            events = events.filter { event in
                guard let eventClimbingTypes = event.climbingType else { return false }
                return !Set(eventClimbingTypes).isDisjoint(with: selectedClimbingTypes)
            }
        }
        
        // Filter by proximity
        if proximityFilter != .all, let userLocation = userLocation {
            events = events.filter { event in
                guard let distance = distanceToEvent(event) else { return false }
                
                switch proximityFilter {
                case .all:
                    return true
                case .nearby:
                    return distance <= 2000 // 2km for nearby
                case .withinFiveKm, .withinTenKm, .withinTwentyKm:
                    guard let maxDistance = proximityFilter.distanceInMeters else { return true }
                    return distance <= maxDistance
                }
            }
        }
        
        // Filter by timeframe
        events = filterByTimeframe(events)
        
        // Filter by favorite gyms
        if showFavoriteGymsOnly {
            let favoriteGymIds = Set(favoriteGyms.map { $0.id })
            events = events.filter { event in
                favoriteGymIds.contains(event.host.id)
            }
        }
        
        // Sort by date (earliest first)
        events = events.sorted(by: { $0.startDate < $1.startDate })
        
        filteredEvents = events
    }
    
    private func filterByTimeframe(_ events: [EventItem]) -> [EventItem] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeframe {
        case .all:
            return events
            
        case .today:
            return events.filter { event in
                calendar.isDate(event.startDate, inSameDayAs: now)
            }
            
        case .thisWeek:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
                  let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end else {
                return events
            }
            return events.filter { event in
                event.startDate >= weekStart && event.startDate < weekEnd
            }
            
        case .thisMonth:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
                  let monthEnd = calendar.dateInterval(of: .month, for: now)?.end else {
                return events
            }
            return events.filter { event in
                event.startDate >= monthStart && event.startDate < monthEnd
            }
            
        case .next7Days:
            let endDate = calendar.date(byAdding: .day, value: 7, to: now) ?? now
            return events.filter { event in
                event.startDate >= now && event.startDate <= endDate
            }
            
        case .next30Days:
            let endDate = calendar.date(byAdding: .day, value: 30, to: now) ?? now
            return events.filter { event in
                event.startDate >= now && event.startDate <= endDate
            }
        }
    }
    
    // MARK: - User Favorites Management
    
    func isEventFavorited(_ event: EventItem) -> Bool {
        return favoritedEventIds.contains(event.id)
    }
    
    func toggleFavorite(for event: EventItem) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if let userId = userRepository.getCurrentAuthUser() {
                    let isCurrentlyFavorite = isEventFavorited(event)
                    
                    // Update in repository
                    _ = try await userRepository.updateUserFavoriteEvents(
                        userId: userId,
                        eventId: event.id,
                        isFavorite: !isCurrentlyFavorite
                    )
                    
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        // Update local state
                        if isCurrentlyFavorite {
                            favoritedEventIds.remove(event.id)
                        } else {
                            favoritedEventIds.insert(event.id)
                        }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    errorMessage = "Failed to update favorite: \(error.localizedDescription)"
                    hasError = true
                }
            }
        }
    }
    
    // MARK: - Location and Distance
    
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
    
    // MARK: - Event Date/Time Formatting
    
    /// Returns formatted date for compact event cards - day name for recurring events, date for one-off events
    func formattedEventDate(_ event: EventItem) -> String {
        let formatter = DateFormatter()
        
        if event.frequency != nil {
            // For recurring events, show the day of the week
            formatter.dateFormat = "EEEE"
            return formatter.string(from: event.startDate)
        } else {
            // For one-off events, show the date
            formatter.dateFormat = "MMM d"
            return formatter.string(from: event.startDate)
        }
    }
    
    /// Returns formatted time for compact event cards - frequency timing for recurring events, time for one-off events
    func formattedEventTime(_ event: EventItem) -> String {
        if let frequency = event.frequency {
            // For recurring events, show the frequency timing
            return frequency.displayName
        } else {
            // For one-off events, show the actual time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            return formatter.string(from: event.startDate)
        }
    }
    
    // MARK: - Utility Methods
    
    func refresh() {
        fetchUserAndFavorites()
        fetchEvents()
        
        // Refresh location if possible
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await locationService.refreshLocationCache()
            } catch {
                // Silently handle location refresh errors
                print("Failed to refresh location: \(error)")
            }
        }
    }
    
    /// Get events grouped by date for sectioned display
    func eventsGroupedByDate() -> [(Date, [EventItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.startDate)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    /// Check if an event requires registration
    func requiresRegistration(_ event: EventItem) -> Bool {
        return event.registrationRequired ?? true
    }
    
    /// Get a formatted string describing current active filters
    func activeFiltersDescription() -> String? {
        guard hasActiveFilters else { return nil }
        
        var descriptions: [String] = []
        
        if !selectedEventTypes.isEmpty {
            let types = selectedEventTypes.map { $0.displayName }.sorted().joined(separator: ", ")
            descriptions.append("Types: \(types)")
        }
        
        if !selectedClimbingTypes.isEmpty {
            let types = selectedClimbingTypes.map { $0.rawValue.capitalized }.sorted().joined(separator: ", ")
            descriptions.append("Climbing: \(types)")
        }
        
        if proximityFilter != .all {
            descriptions.append("Distance: \(proximityFilter.displayName)")
        }
        
        if selectedTimeframe != .all {
            descriptions.append("Time: \(selectedTimeframe.displayName)")
        }
        
        if showFavoriteGymsOnly {
            descriptions.append("Favorite gyms only")
        }
        
        if !searchText.isEmpty {
            descriptions.append("Search: \"\(searchText)\"")
        }
        
        return descriptions.joined(separator: " • ")
    }
}

