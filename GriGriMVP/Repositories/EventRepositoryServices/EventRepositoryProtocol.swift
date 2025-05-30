//
//  EventRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation
import UIKit

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
