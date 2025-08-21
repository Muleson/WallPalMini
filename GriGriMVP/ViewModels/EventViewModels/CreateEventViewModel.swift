//
//  CreateEventViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/05/2025.
//

import Foundation
import UIKit

@MainActor
class CreateEventViewModel: ObservableObject {
    // Published properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedImages: [UIImage] = [] // Add this
    @Published var isUploadingImages = false // Add this
    
    // Dependencies
    private let eventRepository: EventRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol // Add this
    
    init(eventRepository: EventRepositoryProtocol? = nil,
         userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         mediaRepository: MediaRepositoryProtocol = RepositoryFactory.createMediaRepository()) {
        self.userRepository = userRepository
        self.mediaRepository = mediaRepository
        
        // Initialize event repository with dependencies
        if let eventRepository = eventRepository {
            self.eventRepository = eventRepository
        } else {
            self.eventRepository = RepositoryFactory.createEventRepository()
        }
    }
    
    // MARK: - Image Management Methods (Add these)
    
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func clearImages() {
        selectedImages.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Create a new event
    func createEvent(
        name: String,
        description: String,
        startDate: Date,
        endDate: Date? = nil,
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
        
        guard startDate > Date() else {
            errorMessage = "Event start date must be in the future"
            return
        }
        
        let finalEndDate = endDate ?? startDate
        guard finalEndDate >= startDate else {
            errorMessage = "Event end date must be after or equal to start date"
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
            // Upload images first if any are selected
            var mediaItems: [MediaItem]? = nil
            
            if !selectedImages.isEmpty {
                isUploadingImages = true
                mediaItems = []
                
                for image in selectedImages {
                    let mediaItem = try await mediaRepository.uploadImage(
                        image,
                        ownerId: currentUser.id,
                        compressionQuality: 0.8
                    )
                    mediaItems?.append(mediaItem)
                }
                
                isUploadingImages = false
            }
            
            // Create the event object
            let event = EventItem(
                id: UUID().uuidString,
                author: currentUser,
                host: gym,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                eventType: eventType,
                location: location,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                mediaItems: mediaItems,
                registrationLink: registrationLink,
                createdAt: Date(),
                startDate: startDate,
                endDate: finalEndDate,
                isFeatured: false,
                registrationRequired: registrationRequired,
                frequency: nil,
                recurrenceEndDate: nil
            )
            
            // Save to repository
            let eventId = try await eventRepository.createEvent(event)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                self.clearImages()
                // Success - errorMessage remains nil
                print("Event created successfully with ID: \(eventId)")
            }
            
        } catch {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                self.isUploadingImages = false
                self.errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
        }
    }
    
    /// Validate event data
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
    
    /// Reset the view model state
    func resetState() {
        isLoading = false
        errorMessage = nil
    }
}
