//
//  LocalEventRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

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
                type: currentEvent.type,
                location: currentEvent.location,
                description: currentEvent.description,
                mediaItems: mediaItems,
                registrationLink: currentEvent.registrationLink,
                createdAt: currentEvent.createdAt,
                startDate: currentEvent.startDate,
                endDate: currentEvent.endDate,
                isFeatured: currentEvent.isFeatured,
                registrationRequired: currentEvent.registrationRequired
            )
            events[index] = updatedEvent
        }
    }
    
    func deleteEvent(id: String) async throws {
        events.removeAll { $0.id == id }
    }
}
