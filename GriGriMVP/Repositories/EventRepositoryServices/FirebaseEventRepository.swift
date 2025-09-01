//
//  FirebaseEventRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/08/2025.
//

import Foundation
import FirebaseFirestore
import CoreLocation

class FirebaseEventRepository: EventRepositoryProtocol {
    private let db = Firestore.firestore()
    private let eventsCollection = "events"
    private let usersCollection = "users"
    private let gymsCollection = "gyms"
    
    private let userRepository: UserRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         mediaRepository: MediaRepositoryProtocol = RepositoryFactory.createMediaRepository()) {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        self.mediaRepository = mediaRepository
    }
    
    // MARK: - Fetch Methods
    
    func fetchAllEvents() async throws -> [EventItem] {
        let snapshot = try await db.collection(eventsCollection).getDocuments()
        var events: [EventItem] = []
        
        for document in snapshot.documents {
            if let event = try await decodeEvent(document) {
                events.append(event)
            }
        }
        
        return events
    }
    
    func fetchEventsForGym(gymId: String) async throws -> [EventItem] {
        let snapshot = try await db.collection(eventsCollection)
            .whereField("hostId", isEqualTo: gymId)
            .getDocuments()
        
        var events: [EventItem] = []
        
        for document in snapshot.documents {
            if let event = try await decodeEvent(document) {
                events.append(event)
            }
        }
        
        return events
    }
    
    func fetchEventsCreatedByUser(userId: String) async throws -> [EventItem] {
        let snapshot = try await db.collection(eventsCollection)
            .whereField("authorId", isEqualTo: userId)
            .getDocuments()
        
        var events: [EventItem] = []
        
        for document in snapshot.documents {
            if let event = try await decodeEvent(document) {
                events.append(event)
            }
        }
        
        return events
    }
    
    func fetchFavoriteEvents(userId: String) async throws -> [EventItem] {
        // First get the user to retrieve their favorite event IDs
        let userDocument = try await db.collection(usersCollection).document(userId).getDocument()
        guard let favoriteEventIds = userDocument.data()?["favouriteEvents"] as? [String] else {
            return []
        }
        
        // If there are no favorite events, return empty array
        if favoriteEventIds.isEmpty {
            return []
        }
        
        // Firestore limits the IN query to 10 items, so we need to chunk larger arrays
        let chunkedIds = favoriteEventIds.chunked(into: 10)
        var allEvents: [EventItem] = []
        
        // Process each chunk separately
        for chunk in chunkedIds {
            let chunkSnapshot = try await db.collection(eventsCollection)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            for document in chunkSnapshot.documents {
                if let event = try await decodeEvent(document) {
                    allEvents.append(event)
                }
            }
        }
        
        return allEvents
    }
    
    func searchEvents(query: String) async throws -> [EventItem] {
        // If query is empty, return all events
        if query.isEmpty {
            return try await fetchAllEvents()
        }
        
        // Create a query that searches by name or description
        let lowercaseQuery = query.lowercased()
        
        // Using multiple queries for more comprehensive search
        let nameQuery = db.collection(eventsCollection)
            .whereField("name", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        let descriptionQuery = db.collection(eventsCollection)
            .whereField("description", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("description", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        // Execute both queries
        async let nameSnapshot = nameQuery.getDocuments()
        async let descriptionSnapshot = descriptionQuery.getDocuments()
        
        // Combine results
        let (nameResults, descriptionResults) = try await (nameSnapshot, descriptionSnapshot)
        var uniqueEventIds = Set<String>()
        var events: [EventItem] = []
        
        // Process name results
        for document in nameResults.documents {
            let documentId = document.documentID
            if !uniqueEventIds.contains(documentId) {
                uniqueEventIds.insert(documentId)
                if let event = try await decodeEvent(document) {
                    events.append(event)
                }
            }
        }
        
        // Process description results
        for document in descriptionResults.documents {
            let documentId = document.documentID
            if !uniqueEventIds.contains(documentId) {
                uniqueEventIds.insert(documentId)
                if let event = try await decodeEvent(document) {
                    events.append(event)
                }
            }
        }
        
        return events
    }
    
    func getEvent(id: String) async throws -> EventItem? {
        let documentSnapshot = try await db.collection(eventsCollection).document(id).getDocument()
        
        if documentSnapshot.exists {
            return try await decodeEvent(documentSnapshot)
        }
        
        return nil
    }
    
    // MARK: - Create Methods
    
    func createEvent(_ event: EventItem) async throws -> String {
        var eventData = event.toFirestoreData()
        
        // Remove id from data if it exists, since Firestore will generate one
        eventData.removeValue(forKey: "id")
        
        let documentReference = try await db.collection(eventsCollection).addDocument(data: eventData)
        return documentReference.documentID
    }
    
    // MARK: - Update Methods
    
    func updateEvent(_ event: EventItem) async throws -> EventItem {
        let eventData = event.toFirestoreData()
        try await db.collection(eventsCollection).document(event.id).updateData(eventData)
        return event
    }
    
    func updateEventMedia(eventId: String, mediaItems: [MediaItem]?) async throws {
        var updateData: [String: Any] = [:]
        
        if let mediaItems = mediaItems, !mediaItems.isEmpty {
            updateData["mediaItems"] = mediaItems.map { mediaItem in
                return [
                    "id": mediaItem.id,
                    "url": mediaItem.url.absoluteString,
                    "type": mediaItem.type.rawValue,
                    "uploadedAt": mediaItem.uploadedAt.firestoreTimestamp,
                    "ownerId": mediaItem.ownerId
                ]
            }
        } else {
            updateData["mediaItems"] = FieldValue.delete()
        }
        
        try await db.collection(eventsCollection).document(eventId).updateData(updateData)
    }
    
    // MARK: - Delete Methods
    
    func deleteEvent(id: String) async throws {
        // Get event to check for media
        if let event = try await getEvent(id: id),
           let mediaItems = event.mediaItems {
            // Delete associated media items individually
            for mediaItem in mediaItems {
                try? await mediaRepository.deleteMedia(mediaItem)
            }
        }
        
        // Delete event document
        try await db.collection(eventsCollection).document(id).delete()
    }
    
    // MARK: - Helper Methods
    
    private func decodeEvent(_ document: DocumentSnapshot) async throws -> EventItem? {
        guard var data = document.data() else {
            return nil
        }
        
        // Add the ID to the data
        data["id"] = document.documentID
        
        // Get required IDs for related entities
        guard
            let authorId = data["authorId"] as? String,
            let hostId = data["hostId"] as? String
        else {
            return nil
        }
        
        do {
            // Fetch related entities with better error handling
            let author: User?
            let host: Gym?
            
            do {
                author = try await userRepository.getUser(id: authorId)
                if author == nil {
                }
            } catch {
                author = nil
            }
            
            do {
                host = try await gymRepository.getGym(id: hostId)
                if host == nil {
                }
            } catch {
                host = nil
            }
            
            // Create the event with placeholder data first
            guard var event = EventItem(firestoreData: data) else {
                return nil
            }
            
            // Update with actual fetched data if available
            if let author = author {
                event.author = author
            }
            
            if let host = host {
                event.host = host
            } else {
                
            }
            return event
        }
    }
    
    /// Optimized event decoding for display purposes - skips author lookup to reduce database calls
    private func decodeEventForDisplay(_ document: DocumentSnapshot) async throws -> EventItem? {
        guard var data = document.data() else {
            return nil
        }
        
        // Add the ID to the data
        data["id"] = document.documentID
        
        // Get required IDs for related entities
        guard
            let authorId = data["authorId"] as? String,
            let hostId = data["hostId"] as? String
        else {
            return nil
        }
        
        do {
            // Only fetch the host (gym) - skip author for display optimization
            let host: Gym?
            
            do {
                host = try await gymRepository.getGym(id: hostId)
            } catch {
                host = nil
            }
            
            // Create the event with placeholder data first
            guard var event = EventItem(firestoreData: data) else {
                return nil
            }
            
            // Update with actual host data if available
            // Author remains as placeholder since it's not needed for display
            if let host = host {
                event.host = host
            }
            
            return event
        }
    }
    
    /// Helper method to decode multiple events for display purposes
    private func decodeEventsForDisplay(from documents: [DocumentSnapshot]) async throws -> [EventItem] {
        var events: [EventItem] = []
        
        for document in documents {
            if let event = try await decodeEventForDisplay(document) {
                events.append(event)
            }
        }
        
        return events
    }
}

// MARK: - Display-Optimized Methods
extension FirebaseEventRepository {
    
    func fetchAllEventsForDisplay() async throws -> [EventItem] {
        let snapshot = try await db.collection(eventsCollection).getDocuments()
        var events: [EventItem] = []
        
        for document in snapshot.documents {
            if let event = try await decodeEventForDisplay(document) {
                events.append(event)
            }
        }
        
        return events
    }
    
    func fetchEventsForGymDisplay(gymId: String) async throws -> [EventItem] {
        let snapshot = try await db.collection(eventsCollection)
            .whereField("hostId", isEqualTo: gymId)
            .getDocuments()
        
        var events: [EventItem] = []
        
        for document in snapshot.documents {
            if let event = try await decodeEventForDisplay(document) {
                events.append(event)
            }
        }
        
        return events
    }
    
    func fetchFavoriteEventsForDisplay(userId: String) async throws -> [EventItem] {
        // First get the user to retrieve their favorite event IDs
        let userDocument = try await db.collection(usersCollection).document(userId).getDocument()
        guard let favoriteEventIds = userDocument.data()?["favouriteEvents"] as? [String] else {
            return []
        }
        
        // If there are no favorite events, return empty array
        if favoriteEventIds.isEmpty {
            return []
        }
        
        // Firestore limits the IN query to 10 items, so we need to chunk larger arrays
        let chunkedIds = favoriteEventIds.chunked(into: 10)
        var allEvents: [EventItem] = []
        
        // Process each chunk separately
        for chunk in chunkedIds {
            let chunkSnapshot = try await db.collection(eventsCollection)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            for document in chunkSnapshot.documents {
                if let event = try await decodeEventForDisplay(document) {
                    allEvents.append(event)
                }
            }
        }
        
        return allEvents
    }
    
    func searchEventsForDisplay(query: String) async throws -> [EventItem] {
        // If query is empty, return all events for display
        if query.isEmpty {
            return try await fetchAllEventsForDisplay()
        }
        
        // Create a query that searches by name or description
        let lowercaseQuery = query.lowercased()
        
        // Using multiple queries for more comprehensive search
        let nameQuery = db.collection(eventsCollection)
            .whereField("name", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        let descriptionQuery = db.collection(eventsCollection)
            .whereField("description", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("description", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        // Execute both queries
        async let nameSnapshot = nameQuery.getDocuments()
        async let descriptionSnapshot = descriptionQuery.getDocuments()
        
        // Combine results
        let (nameResults, descriptionResults) = try await (nameSnapshot, descriptionSnapshot)
        var uniqueEventIds = Set<String>()
        var events: [EventItem] = []
        
        // Process name results
        for document in nameResults.documents {
            let documentId = document.documentID
            if !uniqueEventIds.contains(documentId) {
                uniqueEventIds.insert(documentId)
                if let event = try await decodeEventForDisplay(document) {
                    events.append(event)
                }
            }
        }
        
        // Process description results
        for document in descriptionResults.documents {
            let documentId = document.documentID
            if !uniqueEventIds.contains(documentId) {
                uniqueEventIds.insert(documentId)
                if let event = try await decodeEventForDisplay(document) {
                    events.append(event)
                }
            }
        }
        
        return events
    }
}

// MARK: - Section-Specific Batch Loading
extension FirebaseEventRepository {
    
    func fetchClassesForHomeSection() async throws -> [EventItem] {
        print("📚 Fetching classes for home section")
        
        // First try to get 5 featured class events
        let featuredQuery = db.collection(eventsCollection)
            .whereField("eventType", isEqualTo: EventType.gymClass.rawValue)
            .whereField("isFeatured", isEqualTo: true)
            .whereField("startDate", isGreaterThan: Date())
            .order(by: "startDate", descending: false)
            .limit(to: 5)
        
        let featuredSnapshot = try await featuredQuery.getDocuments()
        var classEvents = try await decodeEventsForDisplay(from: featuredSnapshot.documents)
        
        // If we need more events, get non-featured events sorted by time proximity
        if classEvents.count < 5 {
            let remainingNeeded = 5 - classEvents.count
            let featuredIds = Set(classEvents.map { $0.id })
            
            let nonFeaturedQuery = db.collection(eventsCollection)
                .whereField("eventType", isEqualTo: EventType.gymClass.rawValue)
                .whereField("startDate", isGreaterThan: Date())
                .order(by: "startDate", descending: false)
                .limit(to: remainingNeeded + featuredIds.count) // Get extra to filter out duplicates
            
            let nonFeaturedSnapshot = try await nonFeaturedQuery.getDocuments()
            let nonFeaturedEvents = try await decodeEventsForDisplay(from: nonFeaturedSnapshot.documents)
            
            // Filter out already fetched featured events and take what we need
            let additionalEvents = nonFeaturedEvents
                .filter { !featuredIds.contains($0.id) }
                .prefix(remainingNeeded)
            
            classEvents.append(contentsOf: additionalEvents)
        }
        
        print("📚 Fetched \(classEvents.count) class events (\(featuredSnapshot.documents.count) featured)")
        return Array(classEvents.prefix(5))
    }
    
    func fetchFeaturedEventsForCarousel() async throws -> [EventItem] {
        print("🎯 Fetching featured events for carousel")
        
        let targetTypes = [EventType.competition.rawValue, EventType.openDay.rawValue, EventType.opening.rawValue]
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        // First try to get featured events with media within 30 days
        let featuredQuery = db.collection(eventsCollection)
            .whereField("eventType", in: targetTypes)
            .whereField("isFeatured", isEqualTo: true)
            .whereField("startDate", isGreaterThan: Date())
            .whereField("startDate", isLessThanOrEqualTo: thirtyDaysFromNow)
            .order(by: "startDate", descending: false)
            .limit(to: 6) // Get a few extra to filter for media
        
        let featuredSnapshot = try await featuredQuery.getDocuments()
        let featuredEvents = try await decodeEventsForDisplay(from: featuredSnapshot.documents)
        
        // Filter for events with media items
        let featuredWithMedia = featuredEvents.filter { event in
            guard let mediaItems = event.mediaItems else { return false }
            return !mediaItems.isEmpty
        }
        
        var carouselEvents = Array(featuredWithMedia.prefix(3))
        
        // If we don't have 3 featured events with media, fall back to non-featured events
        if carouselEvents.count < 3 {
            let remainingNeeded = 3 - carouselEvents.count
            let featuredIds = Set(carouselEvents.map { $0.id })
            
            let nonFeaturedQuery = db.collection(eventsCollection)
                .whereField("eventType", in: targetTypes)
                .whereField("startDate", isGreaterThan: Date())
                .order(by: "startDate", descending: false)
                .limit(to: (remainingNeeded + featuredIds.count) * 2) // Get extra to filter for media
            
            let nonFeaturedSnapshot = try await nonFeaturedQuery.getDocuments()
            let nonFeaturedEvents = try await decodeEventsForDisplay(from: nonFeaturedSnapshot.documents)
            
            // Filter for events with media that aren't already included
            let additionalEventsWithMedia = nonFeaturedEvents
                .filter { event in
                    !featuredIds.contains(event.id) &&
                    event.mediaItems?.isEmpty == false
                }
                .prefix(remainingNeeded)
            
            carouselEvents.append(contentsOf: additionalEventsWithMedia)
        }
        
        print("🎯 Fetched \(carouselEvents.count) carousel events (\(featuredWithMedia.count) featured with media)")
        return Array(carouselEvents.prefix(3))
    }
    
    func fetchSocialEventsForHomeSection(userLocation: CLLocation?) async throws -> [EventItem] {
        print("🤝 Fetching social events for home section")
        
        // First get 2 featured social events
        let featuredQuery = db.collection(eventsCollection)
            .whereField("eventType", isEqualTo: EventType.social.rawValue)
            .whereField("isFeatured", isEqualTo: true)
            .whereField("startDate", isGreaterThan: Date())
            .order(by: "startDate", descending: false)
            .limit(to: 2)
        
        let featuredSnapshot = try await featuredQuery.getDocuments()
        var socialEvents = try await decodeEventsForDisplay(from: featuredSnapshot.documents)
        
        // Get remaining 3 events for proximity sorting
        if socialEvents.count < 5 {
            let remainingNeeded = 5 - socialEvents.count
            let featuredIds = Set(socialEvents.map { $0.id })
            
            let nonFeaturedQuery = db.collection(eventsCollection)
                .whereField("eventType", isEqualTo: EventType.social.rawValue)
                .whereField("startDate", isGreaterThan: Date())
                .order(by: "startDate", descending: false)
                .limit(to: remainingNeeded * 3) // Get extra for location sorting
            
            let nonFeaturedSnapshot = try await nonFeaturedQuery.getDocuments()
            let nonFeaturedEvents = try await decodeEventsForDisplay(from: nonFeaturedSnapshot.documents)
            
            // Filter out featured events
            var proximityEvents = nonFeaturedEvents.filter { !featuredIds.contains($0.id) }
            
            // Sort by proximity if user location is available
            if let userLocation = userLocation {
                proximityEvents = proximityEvents.compactMap { event -> (EventItem, Double)? in
                    // Get location from gym's location data
                    let gymLocation = event.host.location
                    let eventCLLocation = gymLocation.toCLLocation()
                    let distance = userLocation.distance(from: eventCLLocation)
                    return (event, distance)
                }
                .sorted { $0.1 < $1.1 } // Sort by distance
                .map { $0.0 } // Extract events
            }
            
            let additionalEvents = Array(proximityEvents.prefix(remainingNeeded))
            socialEvents.append(contentsOf: additionalEvents)
        }
        
        print("🤝 Fetched \(socialEvents.count) social events (\(featuredSnapshot.documents.count) featured)")
        return Array(socialEvents.prefix(5))
    }
}
