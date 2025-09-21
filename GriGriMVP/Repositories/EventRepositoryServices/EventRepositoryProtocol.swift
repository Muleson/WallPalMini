//
//  EventRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation
import UIKit
import CoreLocation

protocol EventRepositoryProtocol {
    /// Fetch all events
    func fetchAllEvents() async throws -> [EventItem]
    
    /// Fetch events for a specific gym
    func fetchEventsForGym(gymId: String) async throws -> [EventItem]
    
    /// Fetch events created by a specific user
    func fetchEventsCreatedByUser(userId: String) async throws -> [EventItem]
    
    /// Fetch events that a user has favorited
    func fetchFavoriteEvents(userId: String) async throws -> [EventItem]
    
    /// Search for events by name or description
    func searchEvents(query: String) async throws -> [EventItem]
    
    /// Get a specific event by ID
    func getEvent(id: String) async throws -> EventItem?
    
    /// Create a new event
    func createEvent(_ event: EventItem) async throws -> String

    /// Update an existing event
    func updateEvent(_ event: EventItem) async throws -> EventItem

    /// Update an event image
    func updateEventMedia(eventId: String, mediaItems: [MediaItem]?) async throws
    
    /// Delete an event
    func deleteEvent(id: String) async throws
}

// MARK: - Display-Optimized Methods
extension EventRepositoryProtocol {
    /// Fetch all events optimized for display purposes (skips author lookup)
    func fetchAllEventsForDisplay() async throws -> [EventItem] {
        // Default implementation falls back to regular fetch
        return try await fetchAllEvents()
    }
    
    /// Fetch events for a specific gym optimized for display purposes (skips author lookup)
    func fetchEventsForGymDisplay(gymId: String) async throws -> [EventItem] {
        // Default implementation falls back to regular fetch
        return try await fetchEventsForGym(gymId: gymId)
    }
    
    /// Fetch favorite events optimized for display purposes (skips author lookup)
    func fetchFavoriteEventsForDisplay(userId: String) async throws -> [EventItem] {
        // Default implementation falls back to regular fetch
        return try await fetchFavoriteEvents(userId: userId)
    }
    
    /// Search for events optimized for display purposes (skips author lookup)
    func searchEventsForDisplay(query: String) async throws -> [EventItem] {
        // Default implementation falls back to regular fetch
        return try await searchEvents(query: query)
    }
}

// MARK: - Section-Specific Batch Loading
extension EventRepositoryProtocol {
    
    /// Load events optimized for the Classes horizontal scroll section
    /// - Returns: Up to 5 class events (featured first, then by time proximity)
    func fetchClassesForUpcomingView() async throws -> [EventItem] {
        // Default implementation - can be overridden by concrete implementations
        let allEvents = try await fetchAllEventsForDisplay()
        return Array(allEvents.filter { $0.eventType == .gymClass }.prefix(5))
    }
    
    /// Load events optimized for the "Next big sends" featured carousel
    /// - Returns: Up to 3 featured events of competition/openDay/opening types with media
    func fetchFeaturedEventsForCarousel() async throws -> [EventItem] {
        // Default implementation - can be overridden by concrete implementations
        let allEvents = try await fetchAllEventsForDisplay()
        let targetTypes: Set<EventType> = [.competition, .openDay, .opening]
        return Array(allEvents.filter { 
            targetTypes.contains($0.eventType) && 
            $0.isFeatured && 
            $0.mediaItems?.isEmpty == false 
        }.prefix(3))
    }
    
    /// Load events optimized for the Social Sessions horizontal scroll
    /// - Parameters:
    ///   - userLocation: User's location for proximity sorting (optional)
    /// - Returns: Up to 5 social events (2 featured + 3 by proximity)
    func fetchSocialEventsForUpcomingView(userLocation: CLLocation?) async throws -> [EventItem] {
        // Default implementation - can be overridden by concrete implementations
        let allEvents = try await fetchAllEventsForDisplay()
        return Array(allEvents.filter { $0.eventType == .social }.prefix(5))
    }
}
