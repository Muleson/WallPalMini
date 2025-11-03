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

    // MARK: - Filtered Query Methods

    /// Fetch events with server-side filters to minimize database reads
    /// - Parameters:
    ///   - eventTypes: Filter by event types (e.g., gymClass, social)
    ///   - startDateAfter: Only include events starting after this date
    ///   - startDateBefore: Only include events starting before this date
    ///   - isFeatured: Filter by featured status
    ///   - hostGymId: Filter by hosting gym
    ///   - limit: Maximum number of events to return
    /// - Returns: Array of events matching all specified filters
    func fetchEventsWithFilters(
        eventTypes: Set<EventType>?,
        startDateAfter: Date?,
        startDateBefore: Date?,
        isFeatured: Bool?,
        hostGymId: String?,
        limit: Int?
    ) async throws -> [EventItem]

    // MARK: - Section-Specific Batch Loading

    /// Load events optimized for the Classes horizontal scroll section
    /// - Returns: Up to 5 class events (featured first, then by time proximity)
    func fetchClassesForUpcomingView() async throws -> [EventItem]

    /// Load events optimized for the "Next big sends" featured carousel
    /// - Returns: Up to 3 featured events of competition/openDay/opening types with media
    func fetchFeaturedEventsForCarousel() async throws -> [EventItem]

    /// Load events optimized for the Social Sessions horizontal scroll
    /// - Parameters:
    ///   - userLocation: User's location for proximity sorting (optional)
    /// - Returns: Up to 5 social events (2 featured + 3 by proximity)
    func fetchSocialEventsForUpcomingView(userLocation: CLLocation?) async throws -> [EventItem]
}
