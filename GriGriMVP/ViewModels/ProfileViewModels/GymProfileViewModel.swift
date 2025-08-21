//
//  GymProfileViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import Foundation
import Combine
import FirebaseFirestore

class GymProfileViewModel: ObservableObject {
    // Published properties
    @Published var gym: Gym
    @Published var gymEvents: [EventItem] = []
    @Published var isLoadingEvents = false
    @Published var error: String? = nil
    @Published var isFavorite: Bool = false
    
    // Current user data
    private var currentUser: User?
    
    // Computed property for grouped events
    var groupedEvents: [String: [EventItem]] {
        Dictionary(grouping: gymEvents) { event in
            event.eventType.rawValue.capitalized
        }
    }
    
    // Services
    private var cancellables = Set<AnyCancellable>()
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    
    init(gym: Gym, 
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         eventRepository: EventRepositoryProtocol = RepositoryFactory.createEventRepository()) {
        self.gym = gym
        self.gymRepository = gymRepository
        self.userRepository = userRepository
        self.eventRepository = eventRepository
        
        loadGymEvents()
        loadUserAndCheckFavorite()
    }
    
    private func loadUserAndCheckFavorite() {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if let user = try await userRepository.getCurrentUser() {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.currentUser = user
                        self.isFavorite = user.favoriteGyms?.contains(self.gym.id) ?? false
                    }
                }
            } catch {
                print("Error loading user data: \(error)")
            }
        }
    }
    
    func loadGymEvents() {
        isLoadingEvents = true
        error = nil
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let events = try await eventRepository.fetchEventsForGym(gymId: gym.id)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.gymEvents = events
                    self.isLoadingEvents = false
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.error = "Failed to load gym events: \(error.localizedDescription)"
                    self.isLoadingEvents = false
                }
            }
        }
    }
    
    func refreshGymDetails() {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if let updatedGym = try await gymRepository.getGym(id: gym.id) {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.gym = updatedGym
                    }
                }
                
                loadUserAndCheckFavorite()
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.error = "Failed to refresh gym details: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func toggleFavorite() {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if let currentUserId = userRepository.getCurrentAuthUser() {
                    let updatedFavorites = try await userRepository.updateUserFavoriteGyms(
                        userId: currentUserId,
                        gymId: gym.id,
                        isFavorite: !isFavorite
                    )
                    
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.isFavorite.toggle()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.error = "Failed to update favorite status: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Check if an event is favorited
    func isEventFavorited(event: EventItem) -> Bool {
        return currentUser?.favoriteEvents?.contains(event.id) ?? false
    }
    
    // Toggle event favorite
    func toggleEventFavorite(event: EventItem) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if let currentUserId = userRepository.getCurrentAuthUser() {
                    let isCurrentlyFavorite = isEventFavorited(event: event)
                    
                    _ = try await userRepository.updateUserFavoriteEvents(
                        userId: currentUserId,
                        eventId: event.id,
                        isFavorite: !isCurrentlyFavorite
                    )
                    
                    loadUserAndCheckFavorite()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.error = "Failed to update event favorite status: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Helper functions for formatting
    func formatClimbingType(_ type: ClimbingTypes) -> String {
        switch type {
        case .bouldering:
            return "Bouldering"
        case .sport:
            return "Sport"
        case .board:
            return "Board"
        case .gym:
            return "Gym"
        }
    }
}
