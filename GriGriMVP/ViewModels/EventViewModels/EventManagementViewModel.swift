//
//  EventManagementViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/05/2025.
//

import Foundation

@MainActor
class EventManagementViewModel: ObservableObject {
    // Published properties
    @Published var gymEvents: [EventItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Properties
    private let gym: Gym
    private let eventRepository: EventRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(gym: Gym,
         eventRepository: EventRepositoryProtocol? = nil,
         userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
        self.gym = gym
        self.userRepository = userRepository
        
        // Initialize event repository with dependencies
        if let eventRepository = eventRepository {
            self.eventRepository = eventRepository
        } else {
            self.eventRepository = FirebaseEventRepository(
                userRepository: userRepository,
                gymRepository: FirebaseGymRepository()
            )
        }
    }
    
    // MARK: - Public Methods
    
    /// Load all events for the current gym
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let events = try await eventRepository.fetchEventsForGym(gymId: gym.id)
            
            await MainActor.run {
                self.gymEvents = events.sorted { $0.eventDate < $1.eventDate }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                self.isLoading = false
                // For development, fall back to sample data
                self.loadSampleEvents()
            }
        }
    }
    
    /// Delete an event by ID
    func deleteEvent(_ eventId: String) async {
        do {
            try await eventRepository.deleteEvent(id: eventId)
            
            await MainActor.run {
                self.gymEvents.removeAll { $0.id == eventId }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete event: \(error.localizedDescription)"
            }
        }
    }
    
    /// Refresh events from the repository
    func refreshEvents() async {
        await loadEvents()
    }
    
    // MARK: - Private Methods
    
    /// Load sample events for development/testing
    private func loadSampleEvents() {
        // Filter sample events for this gym
        self.gymEvents = SampleData.events.filter { $0.host.id == gym.id }
            .sorted { $0.eventDate < $1.eventDate }
    }
}
