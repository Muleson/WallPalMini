//
//  LocalEventRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import Foundation
import CoreLocation

class LocalEventRepository: EventRepositoryProtocol {
    private var events = SampleData.events
    
    func fetchAllEvents() async throws -> [EventItem] {
        return events
    }
    
    func fetchEventsForGym(gymId: String) async throws -> [EventItem] {
        return SampleData.getEventsForGym(gymId: gymId)
    }
    
    func fetchEventsCreatedByUser(userId: String) async throws -> [EventItem] {
        return SampleData.getEventsCreatedBy(userId: userId)
    }
    
    func fetchFavoriteEvents(userId: String) async throws -> [EventItem] {
        // Get user's favorite event IDs
        guard let user = SampleData.users.first(where: { $0.id == userId }),
              let favoriteEventIds = user.favoriteEvents else {
            return []
        }
        
        return events.filter { favoriteEventIds.contains($0.id) }
    }
    
    func searchEvents(query: String) async throws -> [EventItem] {
        return events.filter { event in
            event.name.localizedCaseInsensitiveContains(query) ||
            event.description.localizedCaseInsensitiveContains(query) == true   //description should be an optional value! Find a fix
        }
    }
    
    func getEvent(id: String) async throws -> EventItem? {
        return events.first { $0.id == id }
    }
    
    func createEvent(_ event: EventItem) async throws -> String {
        events.append(event)
        return event.id
    }
    
    func updateEvent(_ event: EventItem) async throws -> EventItem {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
        return event
    }
    
    func updateEventMedia(eventId: String, mediaItems: [MediaItem]?) async throws {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            let currentEvent = events[index]
            let updatedEvent = EventItem(
                id: currentEvent.id,
                author: currentEvent.author,
                host: currentEvent.host,
                name: currentEvent.name,
                eventType: currentEvent.eventType,
                climbingType: currentEvent.climbingType,
                location: currentEvent.location,
                description: currentEvent.description,
                mediaItems: mediaItems,
                registrationLink: currentEvent.registrationLink,
                createdAt: currentEvent.createdAt,
                startDate: currentEvent.startDate,
                endDate: currentEvent.endDate,
                isFeatured: currentEvent.isFeatured,
                registrationRequired: currentEvent.registrationRequired,
                frequency: currentEvent.frequency,
                recurrenceEndDate: currentEvent.recurrenceEndDate
            )
            events[index] = updatedEvent
        }
    }
    
    func deleteEvent(id: String) async throws {
        events.removeAll { $0.id == id }
    }

    // MARK: - Filtered Query Methods

    func fetchEventsWithFilters(
        eventTypes: Set<EventType>?,
        startDateAfter: Date?,
        startDateBefore: Date?,
        isFeatured: Bool?,
        hostGymId: String?,
        limit: Int?
    ) async throws -> [EventItem] {
        var filtered = events

        // Filter by event types
        if let eventTypes = eventTypes, !eventTypes.isEmpty {
            filtered = filtered.filter { eventTypes.contains($0.eventType) }
        }

        // Filter by start date after
        if let startDate = startDateAfter {
            filtered = filtered.filter { $0.startDate > startDate }
        }

        // Filter by start date before
        if let endDate = startDateBefore {
            filtered = filtered.filter { $0.startDate < endDate }
        }

        // Filter by featured status
        if let featured = isFeatured {
            filtered = filtered.filter { $0.isFeatured == featured }
        }

        // Filter by host gym
        if let gymId = hostGymId {
            filtered = filtered.filter { $0.host.id == gymId }
        }

        // Sort by start date
        filtered = filtered.sorted { $0.startDate < $1.startDate }

        // Apply limit
        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }

        return filtered
    }

    // MARK: - Section-Specific Batch Loading

    func fetchClassesForUpcomingView() async throws -> [EventItem] {
        let classEvents = events.filter { $0.eventType == .gymClass && $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
        return Array(classEvents.prefix(5))
    }

    func fetchFeaturedEventsForCarousel() async throws -> [EventItem] {
        let targetTypes: Set<EventType> = [.competition, .openDay, .opening]
        let featuredEvents = events.filter {
            targetTypes.contains($0.eventType) &&
            $0.isFeatured &&
            $0.mediaItems?.isEmpty == false &&
            $0.startDate > Date()
        }
        .sorted { $0.startDate < $1.startDate }
        return Array(featuredEvents.prefix(3))
    }

    func fetchSocialEventsForUpcomingView(userLocation: CoreLocation.CLLocation?) async throws -> [EventItem] {
        let socialEvents = events.filter { $0.eventType == .social && $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
        return Array(socialEvents.prefix(5))
    }
}
