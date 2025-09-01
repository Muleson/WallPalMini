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
    private let homeSectionLoader: HomeSectionLoader
    
    // MARK: - Filter Properties
    @Published var selectedEventTypes: Set<EventType> = []
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
    
    // MARK: - Private Properties
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Services and repositories
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    
    // Current user data
    private var currentUser: User?
    private var favoritedEventIds: Set<String> = []
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
        selectedTimeframe != .all || 
        showFavoriteGymsOnly || 
        !searchText.isEmpty
    }
    
    // MARK: - Section-Specific Computed Properties
    
    /// Class events optimized for horizontal scroll section
    var classEvents: [EventItem] {
        homeSectionLoader.sectionEvents.classes
    }
    
    /// Featured events optimized for carousel section
    var featuredCarouselEvents: [EventItem] {
        homeSectionLoader.sectionEvents.featuredCarousel
    }
    
    /// Social events optimized for horizontal scroll section
    var socialEvents: [EventItem] {
        homeSectionLoader.sectionEvents.socialEvents
    }
    
    /// Whether section-specific loading is in progress
    var isSectionLoading: Bool {
        homeSectionLoader.sectionEvents.isLoading
    }
    
    // MARK: - Initialization
    
    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         eventRepository: EventRepositoryProtocol? = nil) {
        let repository = eventRepository ?? RepositoryFactory.createEventRepository()
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        self.eventRepository = repository
        self.homeSectionLoader = HomeSectionLoader(eventRepository: repository)
        
        // Observe homeSectionLoader changes to trigger UI updates
        homeSectionLoader.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        setupLocationObservers()
        setupFilterObservers()
        fetchUserAndFavorites()
        loadHomeSections() // Load optimized home sections instead of all events
        checkCachedLocation()
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
        Publishers.CombineLatest4(
            $selectedEventTypes,
            $selectedTimeframe,
            $showFavoriteGymsOnly,
            $searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _, _ in
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
    
    /// Load home section events optimized for the UpcomingEventsView
    func loadHomeSections(forceRefresh: Bool = false) {
        homeSectionLoader.loadAllSections(userLocation: userLocation, forceRefresh: forceRefresh)
    }
    
    /// Refresh a specific home section
    func refreshHomeSection(_ section: HomeSection) {
        homeSectionLoader.refreshSection(section, userLocation: userLocation)
    }
    
    /// Legacy method - still used for search and filter functionality
    func fetchEvents() {
        isLoadingEvents = true
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Use optimized display method to reduce database calls
                let events = try await eventRepository.fetchAllEventsForDisplay()
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    // Only show upcoming events
                    allEvents = events.filter { $0.startDate > Date() }
                        .sorted(by: { $0.startDate < $1.startDate })
                    
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
    
    // MARK: - Filter Management
    
    func toggleEventType(_ eventType: EventType) {
        if selectedEventTypes.contains(eventType) {
            selectedEventTypes.remove(eventType)
        } else {
            selectedEventTypes.insert(eventType)
        }
    }
    
    func clearAllFilters() {
        selectedEventTypes.removeAll()
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
    
    private func applyFilters() {
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

