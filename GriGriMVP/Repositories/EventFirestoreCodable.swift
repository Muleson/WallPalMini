//
//  EventFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation
import FirebaseFirestore

// Implement the FirestoreCodable extension for EventItem
extension EventItem: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "type": type.rawValue,
            "location": location,
            "description": description,
            "createdAt": createdAt.firestoreTimestamp,
            "eventDate": eventDate.firestoreTimestamp,
            "isFeatured": isFeatured,
            "registrationRequired": registrationRequired,
            // We'll store IDs for these objects and fetch them separately
            "authorId": author.id,
            "hostId": host.id
        ]
        
        // Add optional fields if they exist
        if let mediaItems = mediaItems {
            // Assuming MediaItem has a toFirestoreData method as well
            data["mediaItems"] = mediaItems.toFirestoreData()
        }
        
        if let registrationLink = registrationLink {
            data["registrationLink"] = registrationLink
        }
        
        return data
    }
    
    // Protocol-conforming initializer
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let authorId = firestoreData["authorId"] as? String,
            let hostId = firestoreData["hostId"] as? String,
            let name = firestoreData["name"] as? String,
            let typeRawValue = firestoreData["type"] as? String,
            let type = EventType(rawValue: typeRawValue),
            let location = firestoreData["location"] as? String,
            let description = firestoreData["description"] as? String,
            let createdAtTimestamp = firestoreData["createdAt"] as? Timestamp,
            let eventDateTimestamp = firestoreData["eventDate"] as? Timestamp,
            let isFeatured = firestoreData["isFeatured"] as? Bool,
            let registrationRequired = firestoreData["registrationRequired"] as? Bool
        else {
            return nil
        }
        
        // Create placeholder objects with minimal info
        let placeholderAuthor = User.placeholder(id: authorId)
        let placeholderHost = Gym.placeholder(id: hostId)
        
        self.id = id
        self.author = placeholderAuthor
        self.host = placeholderHost
        self.name = name
        self.type = type
        self.location = location
        self.description = description
        self.createdAt = createdAtTimestamp.dateValue
        self.eventDate = eventDateTimestamp.dateValue
        self.isFeatured = isFeatured
        self.registrationRequired = registrationRequired
        
        // Handle optional properties
        self.registrationLink = firestoreData["registrationLink"] as? String
        
        // Handle media items if they exist
        if let mediaItemsData = firestoreData["mediaItems"] as? [String: Any],
           let mediaItem = MediaItem(firestoreData: mediaItemsData) {
            self.mediaItems = mediaItem
        } else {
            self.mediaItems = nil
        }
    }
    
    // Custom initializer with full object parameters
    init?(firestoreData: [String: Any], author: User, host: Gym) {
        guard
            let id = firestoreData["id"] as? String,
            let name = firestoreData["name"] as? String,
            let typeRawValue = firestoreData["type"] as? String,
            let type = EventType(rawValue: typeRawValue),
            let location = firestoreData["location"] as? String,
            let description = firestoreData["description"] as? String,
            let createdAtTimestamp = firestoreData["createdAt"] as? Timestamp,
            let eventDateTimestamp = firestoreData["eventDate"] as? Timestamp,
            let isFeatured = firestoreData["isFeatured"] as? Bool,
            let registrationRequired = firestoreData["registrationRequired"] as? Bool
        else {
            return nil
        }
        
        self.id = id
        self.author = author
        self.host = host
        self.name = name
        self.type = type
        self.location = location
        self.description = description
        self.createdAt = createdAtTimestamp.dateValue
        self.eventDate = eventDateTimestamp.dateValue
        self.isFeatured = isFeatured
        self.registrationRequired = registrationRequired
        
        // Handle optional properties
        self.registrationLink = firestoreData["registrationLink"] as? String
        
        // Handle media items if they exist
        if let mediaItemsData = firestoreData["mediaItems"] as? [String: Any],
           let mediaItem = MediaItem(firestoreData: mediaItemsData) {
            self.mediaItems = mediaItem
        } else {
            self.mediaItems = nil
        }
    }
}

// Implement the FirebaseEventRepository class
class FirebaseEventRepository: EventRepositoryProtocol {
    private let db = Firestore.firestore()
    private let eventsCollection = "events"
    private let usersCollection = "users"
    private let gymsCollection = "gyms"
    
    private let userRepository: UserRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol, gymRepository: GymRepositoryProtocol) {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
    }
    
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
    
    func createEvent(_ event: EventItem) async throws -> String {
        var eventData = event.toFirestoreData()
        
        // Remove id from data if it exists, since Firestore will generate one
        eventData.removeValue(forKey: "id")
        
        let documentReference = try await db.collection(eventsCollection).addDocument(data: eventData)
        return documentReference.documentID
    }
    
    func updateEvent(_ event: EventItem) async throws {
        let eventData = event.toFirestoreData()
        try await db.collection(eventsCollection).document(event.id).updateData(eventData)
    }
    
    func deleteEvent(id: String) async throws {
        try await db.collection(eventsCollection).document(id).delete()
    }
    
    // Helper method to decode an event document with related entities
    private func decodeEvent(_ document: DocumentSnapshot) async throws -> EventItem? {
        guard
            let data = document.data(),
            let authorId = data["authorId"] as? String,
            let hostId = data["hostId"] as? String,
            let author = try await userRepository.getUser(id: authorId),
            let host = try await gymRepository.getGym(id: hostId)
        else {
            return nil
        }
        
        // Add the ID to the data
        var eventData = data
        eventData["id"] = document.documentID
        
        return EventItem(firestoreData: eventData, author: author, host: host)
    }
}
