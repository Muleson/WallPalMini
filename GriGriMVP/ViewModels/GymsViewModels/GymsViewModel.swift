//
//  GymsViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/06/2025.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class GymsViewModel: ObservableObject {
    @Published var gyms: [Gym] = []
    @Published var events: [EventItem] = []
    @Published var favoriteGyms: [Gym] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var selectedFilterTypes: Set<GymFilterType> = [.all]
    @Published var showFilter = false
    
    // Add navigation state
    @Published var showGymProfile = false
    @Published var selectedGym: Gym?
    
    // Gym Profile specific properties
    @Published var selectedGymEvents: [EventItem] = []
    @Published var isLoadingEvents = false
    
    private let locationService = LocationService.shared
    private let gymRepository: GymRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let appState: AppState
    private var userLocation: CLLocation?
    
    // Get current user ID from AppState
    private var currentUserId: String? {
        return appState.user?.id
    }
    
    // Public getter for appState
    var currentAppState: AppState {
        return appState
    }
    
    // MARK: - Updated Location Methods
    
    var gymsByDistance: [Gym] {
        // Use cached location from LocationService
        guard let userLocation = locationService.getCachedLocation() else {
            return gyms
        }
        
        do {
            return try locationService.sortEventsByProximity(
                gyms,
                locationExtractor: { $0.location }
            )
        } catch {
            print("Failed to sort gyms by proximity: \(error)")
            return gyms
        }
    }
    
    var nonFavoriteGymsByDistance: [Gym] {
        let favoriteGymIds = Set(favoriteGyms.map { $0.id })
        let filteredGyms = filterGyms(gymsByDistance.filter { !favoriteGymIds.contains($0.id) })
        return filteredGyms
    }
    
    // MARK: - Filter Logic
    
    private func filterGyms(_ gyms: [Gym]) -> [Gym] {
        // If "All" is selected, return all gyms
        if selectedFilterTypes.contains(.all) {
            return gyms
        }
        
        // If no specific types selected, return all gyms
        if selectedFilterTypes.isEmpty {
            return gyms
        }
        
        return gyms.filter { gym in
            // Check if gym has ALL of the selected climbing types (AND logic)
            return selectedFilterTypes.allSatisfy { filterType in
                switch filterType {
                case .all:
                    return true
                case .boulder:
                    return gym.climbingType.contains(.bouldering)
                case .sport:
                    return gym.climbingType.contains(.sport)
                }
            }
        }
    }
    
    func toggleFilter() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showFilter.toggle()
        }
    }
    
    func updateFilterSelection(_ newSelection: Set<GymFilterType>) {
        selectedFilterTypes = newSelection
    }
    
    // MARK: - Gym Profile Computed Properties
    
    var groupedEventsForSelectedGym: [String: [EventItem]] {
        guard selectedGym != nil else { return [:] }
        return Dictionary(grouping: selectedGymEvents) { event in
            event.eventType.rawValue.capitalized
        }
    }

    // Next featured event (exclude social and class types) - future events only
    var nextFeaturedEventForSelectedGym: EventItem? {
        let now = Date()
        let featuredEvents = selectedGymEvents
            .filter { $0.startDate > now && $0.eventType != .social && $0.eventType != .gymClass }
            .sorted { $0.startDate < $1.startDate }
        
        return featuredEvents.first
    }

    // Upcoming class events for selected gym (future-only, sorted)
    var upcomingClassEventsForSelectedGym: [EventItem] {
        let now = Date()
        let classEvents = selectedGymEvents
            .filter { $0.startDate > now && $0.eventType == .gymClass }
            .sorted { $0.startDate < $1.startDate }
        
        return classEvents
    }
    
    init(
        gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
        eventRepository: EventRepositoryProtocol = RepositoryFactory.createEventRepository(),
        userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
        appState: AppState
    ) {
        self.gymRepository = gymRepository
        self.eventRepository = eventRepository
        self.userRepository = userRepository
        self.appState = appState
        setupLocationObservation()
    }
    
    private func setupLocationObservation() {
        // Observe cached location changes
        locationService.$cachedLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cachedLocation in
                self?.userLocation = cachedLocation
            }
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user location
            await loadUserLocation()
            
            // Load gym and event data concurrently
            async let gymsTask = loadGyms()
            async let eventsTask = loadEvents()
            async let favoritesTask = loadFavoriteGyms()
            
            let (loadedGyms, loadedEvents, loadedFavorites) = try await (gymsTask, eventsTask, favoritesTask)
            
            self.gyms = loadedGyms
            self.events = loadedEvents
            self.favoriteGyms = loadedFavorites
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func loadFavoriteGymsOnly() async {
        errorMessage = nil
        
        do {
            let loadedFavorites = try await loadFavoriteGyms()
            self.favoriteGyms = loadedFavorites
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserLocation() async {
        do {
            userLocation = try await locationService.requestCurrentLocation()
        } catch LocationError.cacheExpired {
            // Try to refresh cache
            do {
                try await locationService.refreshLocationCache()
                userLocation = try await locationService.requestCurrentLocation()
            } catch {
                print("Failed to get user location after refresh: \(error.localizedDescription)")
            }
        } catch {
            print("Failed to get user location: \(error.localizedDescription)")
            // Continue without location - gyms will be shown in default order
        }
    }
    
    private func loadGyms() async throws -> [Gym] {
        return try await gymRepository.fetchAllGyms()
    }
    
    private func loadEvents() async throws -> [EventItem] {
        return try await eventRepository.fetchAllEvents()
    }
    
    private func loadFavoriteGyms() async throws -> [Gym] {
        guard let user = appState.user,
              let favoriteGymIds = user.favoriteGyms,
              !favoriteGymIds.isEmpty else {
            return []
        }
        
        // Fetch the actual gym objects
        var favorites: [Gym] = []
        for gymId in favoriteGymIds {
            if let gym = try await gymRepository.getGym(id: gymId) {
                favorites.append(gym)
            }
        }
        
        return favorites
    }
    
    func eventsForGym(_ gymId: String) -> [EventItem] {
        return events.filter { $0.host.id == gymId }
    }
    
    func toggleFavoriteGym(_ gym: Gym) async {
        guard let userId = currentUserId else {
            errorMessage = "Please sign in to favorite gyms"
            return
        }
        
        do {
            let isFavorite = favoriteGyms.contains(where: { $0.id == gym.id })
            
            // Optimistically update the UI
            if isFavorite {
                favoriteGyms.removeAll { $0.id == gym.id }
            } else {
                favoriteGyms.append(gym)
            }
            
            // Update the backend
            let updatedFavoriteIds = try await userRepository.updateUserFavoriteGyms(
                userId: userId,
                gymId: gym.id,
                isFavorite: !isFavorite
            )
            
            // Update the user in AppState
            if var updatedUser = appState.user {
                updatedUser.favoriteGyms = updatedFavoriteIds
                appState.updateAuthState(user: updatedUser)
            }
            
        } catch {
            errorMessage = "Failed to update favorite gym: \(error.localizedDescription)"
            // Revert the local change if backend update failed
            if favoriteGyms.contains(where: { $0.id == gym.id }) {
                favoriteGyms.removeAll { $0.id == gym.id }
            } else {
                favoriteGyms.append(gym)
            }
        }
    }
    
    func searchGyms(_ query: String) async {
        do {
            isLoading = true
            let searchResults = try await gymRepository.searchGyms(query: query)
            self.gyms = searchResults
            isLoading = false
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func distanceToGym(_ gym: Gym) -> String? {
        // Use cached location directly
        guard let userLocation = locationService.getCachedLocation() else { return nil }
        
        let distance = locationService.distance(from: userLocation, to: gym.location)
        
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else if distance < 10000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return String(format: "%.0fkm", distance / 1000)
        }
    }
    
    func openGymInMaps(_ gym: Gym) {
        locationService.openGymInMaps(gym)
    }
    
    func isGymFavorited(_ gym: Gym) -> Bool {
        // First check the loaded favoriteGyms array
        if favoriteGyms.contains(where: { $0.id == gym.id }) {
            return true
        }
        
        // Fallback: check directly from appState user favoriteGyms
        if let user = appState.user,
           let favoriteGymIds = user.favoriteGyms {
            return favoriteGymIds.contains(gym.id)
        }
        
        return false
    }
    
    // MARK: - Gym Profile Methods
    
    func loadEventsForSelectedGym() async {
        guard let selectedGym = selectedGym else { 
            return 
        }
        
        await loadEventsForGym(selectedGym)
    }
    
    func loadEventsForGym(_ gym: Gym) async {
        isLoadingEvents = true
        
        do {
            // Use optimized display method to reduce database calls
            let events = try await eventRepository.fetchEventsForGymDisplay(gymId: gym.id)
            
            // Only update selectedGymEvents if this is still the selected gym
            if selectedGym?.id == gym.id {
                self.selectedGymEvents = events
            }
        } catch {
            errorMessage = "Failed to load gym events: \(error.localizedDescription)"
        }
        
        isLoadingEvents = false
    }
    
    func refreshSelectedGymDetails() async {
        guard let selectedGym = selectedGym else { return }
        
        do {
            if let updatedGym = try await gymRepository.getGym(id: selectedGym.id) {
                self.selectedGym = updatedGym
                
                // Update in main arrays too
                if let index = gyms.firstIndex(where: { $0.id == updatedGym.id }) {
                    gyms[index] = updatedGym
                }
                if let favoriteIndex = favoriteGyms.firstIndex(where: { $0.id == updatedGym.id }) {
                    favoriteGyms[favoriteIndex] = updatedGym
                }
            }
        } catch {
            errorMessage = "Failed to refresh gym details: \(error.localizedDescription)"
        }
    }
    
    func isEventFavorited(_ event: EventItem) -> Bool {
        return appState.user?.favoriteEvents?.contains(event.id) ?? false
    }
    
    func toggleEventFavorite(_ event: EventItem) async {
        guard let userId = currentUserId else {
            errorMessage = "Please sign in to favorite events"
            return
        }
        
        do {
            let isCurrentlyFavorite = isEventFavorited(event)
            
            _ = try await userRepository.updateUserFavoriteEvents(
                userId: userId,
                eventId: event.id,
                isFavorite: !isCurrentlyFavorite
            )
            
            // Refresh user data to update favorites
            if let updatedUser = try await userRepository.getUser(id: userId) {
                appState.updateAuthState(user: updatedUser)
            }
        } catch {
            errorMessage = "Failed to update event favorite: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Gym Management Methods (for gym owners/staff)
    
    func updateGym(_ gym: Gym) async throws -> Gym {
        let updatedGym = try await gymRepository.updateGym(gym)
        
        // Update local array
        if let index = gyms.firstIndex(where: { $0.id == updatedGym.id }) {
            gyms[index] = updatedGym
        }
        
        // Update favorites if needed
        if let favoriteIndex = favoriteGyms.firstIndex(where: { $0.id == updatedGym.id }) {
            favoriteGyms[favoriteIndex] = updatedGym
        }
        
        return updatedGym
    }
    
    func deleteGym(_ gym: Gym) async throws {
        try await gymRepository.deleteGym(id: gym.id)
        
        // Remove from local arrays
        gyms.removeAll { $0.id == gym.id }
        favoriteGyms.removeAll { $0.id == gym.id }
    }
    
    func selectGym(_ gym: Gym) {
        selectedGym = gym
        showGymProfile = true
        
        // Clear previous events first to avoid showing stale data
        selectedGymEvents = []
        
        // Load events for the selected gym
        Task {
            await loadEventsForGym(gym)
        }
    }
}

// MARK: - Extensions for LocationService

extension LocationService {
    func openGymInMaps(_ gym: Gym) {
        let latitude = gym.location.latitude
        let longitude = gym.location.longitude
        let urlString = "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(gym.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
