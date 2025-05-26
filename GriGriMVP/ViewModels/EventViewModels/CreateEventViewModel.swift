//
//  CreateEventViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/05/2025.
//

import Foundation

@MainActor
class CreateEventViewModel: ObservableObject {
    // Published properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let eventRepository: EventRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(eventRepository: EventRepositoryProtocol? = nil,
         userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
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
    
    /// Create a new event
    func createEvent(
        name: String,
        description: String,
        eventDate: Date,
        eventType: EventType,
        location: String,
        registrationRequired: Bool,
        registrationLink: String?,
        gym: Gym
    ) async {
        // Validate input
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event name is required"
            return
        }
        
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event description is required"
            return
        }
        
        guard eventDate > Date() else {
            errorMessage = "Event date must be in the future"
            return
        }
        
        // Get current user as event author
        guard let currentUser = try? await userRepository.getCurrentUser() else {
            errorMessage = "You must be logged in to create events"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create the event object
            let event = EventItem(
                id: UUID().uuidString,
                author: currentUser,
                host: gym,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: eventType,
                location: location,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                mediaItems: nil, // No media upload in this version
                registrationLink: registrationLink,
                createdAt: Date(),
                eventDate: eventDate,
                isFeatured: false, // Events are not featured by default
                registrationRequired: registrationRequired
            )
            
            // Save to repository
            let eventId = try await eventRepository.createEvent(event)
            
            await MainActor.run {
                self.isLoading = false
                // Success - errorMessage remains nil
                print("Event created successfully with ID: \(eventId)")
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
        }
    }
    
    /// Validate event data
    func validateEventData(
        name: String,
        description: String,
        eventDate: Date,
        registrationRequired: Bool,
        registrationLink: String?
    ) -> String? {
        // Check required fields
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Event name is required"
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Event description is required"
        }
        
        // Check event date
        if eventDate <= Date() {
            return "Event date must be in the future"
        }
        
        // Check registration link if registration is required
        if registrationRequired {
            if let link = registrationLink, !link.isEmpty {
                // Basic URL validation
                if !link.hasPrefix("http://") && !link.hasPrefix("https://") {
                    return "Registration link must be a valid URL (starting with http:// or https://)"
                }
            }
        }
        
        return nil // No validation errors
    }
    
    /// Reset the view model state
    func resetState() {
        isLoading = false
        errorMessage = nil
    }
}
