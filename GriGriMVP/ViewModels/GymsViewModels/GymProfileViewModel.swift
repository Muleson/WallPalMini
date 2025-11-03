//
//  GymProfileViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/10/2025.
//

import Foundation
import SwiftUI

enum GymProfileTab: String, CaseIterable {
    case events = "Events"
    case info = "Info"
}

@MainActor
class GymProfileViewModel: ObservableObject {
    @Published var selectedTab: GymProfileTab = .events
    @Published var gym: Gym
    @Published var events: [EventItem] = []
    @Published var isLoadingEvents = false
    @Published var errorMessage: String?
    @Published var isFavorite = false
    
    private let gymsViewModel: GymsViewModel
    private let appState: AppState
    
    // MARK: - Computed Properties
    
    var nextFeaturedEvent: EventItem? {
        events.first { event in
            event.isFeatured && event.startDate > Date()
        }
    }
    
    var upcomingClassEvents: [EventItem] {
        events.filter { event in
            // Only include gym classes
            guard event.eventType == .gymClass else { return false }
            
            // Include if it's a future event
            if event.startDate > Date() {
                return true
            }
            
            // Include if it's a recurring event (even if original start date is in the past)
            if event.frequency != nil && event.frequency != .oneTime {
                // Check if the recurring event is still active (hasn't ended)
                if let recurrenceEndDate = event.recurrenceEndDate {
                    return recurrenceEndDate > Date()
                }
                return true // No end date means ongoing
            }
            
            // Exclude past one-time events
            return false
        }.sorted { $0.startDate < $1.startDate }
    }
    
    var hasUpcomingEvents: Bool {
        nextFeaturedEvent != nil || !upcomingClassEvents.isEmpty
    }
    
    // MARK: - Initialization
    
    init(gym: Gym, gymsViewModel: GymsViewModel, appState: AppState) {
        self.gym = gym
        self.gymsViewModel = gymsViewModel
        self.appState = appState
        self.isFavorite = gymsViewModel.isGymFavorited(gym)
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: GymProfileTab) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
    }
    
    // MARK: - Data Loading
    
    func loadGymData() async {
        // Update gym details if needed
        gymsViewModel.selectedGym = gym
        
        // Load events for this gym
        await loadEvents()
        
        // Update favorite status
        await updateFavoriteStatus()
    }
    
    func refreshGymData() async {
        await gymsViewModel.refreshSelectedGymDetails()
        await loadEvents()
        await updateFavoriteStatus()
    }
    
    private func loadEvents() async {
        isLoadingEvents = true
        await gymsViewModel.loadEventsForGym(gym)
        events = gymsViewModel.selectedGymEvents
        isLoadingEvents = false
    }
    
    private func updateFavoriteStatus() async {
        isFavorite = gymsViewModel.isGymFavorited(gym)
    }
    
    // MARK: - Actions

    func toggleFavorite() async {
        await gymsViewModel.toggleFavoriteGym(gym)
        await updateFavoriteStatus()
    }

    func isEventFavorited(_ event: EventItem) -> Bool {
        return appState.user?.favoriteEvents?.contains(event.id) ?? false
    }

    func toggleFavorite(for event: EventItem) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Get current user ID from app state
                guard let user = appState.user else {
                    print("No user available to toggle favorite")
                    return
                }

                // Check if event is currently favorited
                let isCurrentlyFavorite = user.favoriteEvents?.contains(event.id) ?? false

                // Toggle favorite status via repository
                _ = try await RepositoryFactory.createUserRepository().updateUserFavoriteEvents(
                    userId: user.id,
                    eventId: event.id,
                    isFavorite: !isCurrentlyFavorite
                )

                // Optionally refresh user data to update local state
                await appState.checkAuthState()
            } catch {
                print("Error toggling favorite: \(error.localizedDescription)")
            }
        }
    }
    
    func openGymInMaps() -> URL? {
        let lat = gym.location.latitude
        let lon = gym.location.longitude
        let name = gym.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?ll=\(lat),\(lon)&q=\(name)"
        return URL(string: urlString)
    }
    
    // MARK: - Content Helpers
    
    var shouldShowEventsContent: Bool {
        selectedTab == .events
    }
    
    var shouldShowInfoContent: Bool {
        selectedTab == .info
    }
    
    var hasAmenities: Bool {
        !gym.amenities.isEmpty
    }
}