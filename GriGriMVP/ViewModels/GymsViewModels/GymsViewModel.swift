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
        return favoriteGyms.contains(where: { $0.id == gym.id })
    }
    
    // MARK: - Gym Management Methods (for gym owners/staff)
    
    func getGymsUserCanManage() async throws -> [Gym] {
        guard let userId = currentUserId else {
            throw NSError(domain: "GymsViewModel", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        return try await gymRepository.getGymsUserCanManage(userId: userId)
    }
    
    func createGym(_ gym: Gym) async throws -> Gym {
        let createdGym = try await gymRepository.createGym(gym)
        
        // Add to local array if it's not already there
        if !gyms.contains(where: { $0.id == createdGym.id }) {
            gyms.append(createdGym)
        }
        
        return createdGym
    }
    
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
