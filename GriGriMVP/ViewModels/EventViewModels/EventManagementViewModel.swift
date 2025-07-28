//
//  EventManagementViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/05/2025.
//

import Foundation
import UIKit

@MainActor
class EventManagementViewModel: ObservableObject {
    // Published properties
    @Published var gymEvents: [EventItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Edit mode properties
    @Published var selectedImages: [UIImage] = []
    @Published var isUploadingImages = false
    @Published var isEditingEvent = false
    
    // Properties
    private let gym: Gym
    private let eventRepository: EventRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    init(gym: Gym,
         eventRepository: EventRepositoryProtocol? = nil,
         userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         mediaRepository: MediaRepositoryProtocol = FirebaseMediaRepository()) {
        self.gym = gym
        self.userRepository = userRepository
        self.mediaRepository = mediaRepository
        
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
    
    // MARK: - Event Management Methods
    
    /// Load all events for the current gym
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let events = try await eventRepository.fetchEventsForGym(gymId: gym.id)
            
            await MainActor.run {
                self.gymEvents = events.sorted { $0.startDate < $1.startDate }
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
    
    // MARK: - Event Editing Methods
    
    /// Update an existing event
    func updateEvent(
        eventId: String,
        name: String,
        description: String,
        startDate: Date,
        endDate: Date? = nil,
        eventType: EventType,
        location: String,
        registrationRequired: Bool,
        registrationLink: String?
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
        
        guard startDate > Date() else {
            errorMessage = "Event start date must be in the future"
            return
        }
        
        let finalEndDate = endDate ?? startDate
        guard finalEndDate >= startDate else {
            errorMessage = "Event end date must be after or equal to start date"
            return
        }
        
        // Find the existing event
        guard let existingEvent = gymEvents.first(where: { $0.id == eventId }) else {
            errorMessage = "Event not found"
            return
        }
        
        isEditingEvent = true
        errorMessage = nil
        
        do {
            // Upload new images if any are selected
            var updatedMediaItems = existingEvent.mediaItems
            
            if !selectedImages.isEmpty {
                isUploadingImages = true
                
                if updatedMediaItems == nil {
                    updatedMediaItems = []
                }
                
                for image in selectedImages {
                    let mediaItem = try await mediaRepository.uploadImage(
                        image,
                        ownerId: existingEvent.author.id,
                        compressionQuality: 0.8
                    )
                    updatedMediaItems?.append(mediaItem)
                }
                
                isUploadingImages = false
            }
            
            // Create updated event object
            let updatedEvent = EventItem(
                id: existingEvent.id,
                author: existingEvent.author,
                host: existingEvent.host,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: eventType,
                location: location,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                mediaItems: updatedMediaItems,
                registrationLink: registrationLink,
                createdAt: existingEvent.createdAt,
                startDate: startDate,
                endDate: finalEndDate,
                isFeatured: existingEvent.isFeatured,
                registrationRequired: registrationRequired
            )
            
            // Update in repository
            try await eventRepository.updateEvent(updatedEvent)
            
            await MainActor.run {
                // Update local array
                if let index = self.gymEvents.firstIndex(where: { $0.id == eventId }) {
                    self.gymEvents[index] = updatedEvent
                    self.gymEvents.sort { $0.startDate < $1.startDate }
                }
                
                self.isEditingEvent = false
                self.clearSelectedImages()
                print("Event updated successfully")
            }
            
        } catch {
            await MainActor.run {
                self.isEditingEvent = false
                self.isUploadingImages = false
                self.errorMessage = "Failed to update event: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Image Management Methods
    
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    func removeSelectedImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func clearSelectedImages() {
        selectedImages.removeAll()
    }
    
    // MARK: - Validation Methods
    
    /// Validate event data for editing
    func validateEventData(
        name: String,
        description: String,
        startDate: Date,
        endDate: Date? = nil,
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
        
        // Check event dates
        if startDate <= Date() {
            return "Event start date must be in the future"
        }
        
        if let endDate = endDate, endDate < startDate {
            return "Event end date must be after or equal to start date"
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
    
    // MARK: - Private Methods
    
    /// Load sample events for development/testing
    private func loadSampleEvents() {
        // Filter sample events for this gym
        self.gymEvents = SampleData.events.filter { $0.host.id == gym.id }
            .sorted { $0.startDate < $1.startDate }
    }
}
