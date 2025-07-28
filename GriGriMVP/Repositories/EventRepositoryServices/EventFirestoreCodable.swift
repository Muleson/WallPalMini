//
//  EventFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation
import FirebaseFirestore

extension EventItem: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "type": type.rawValue,
            "location": location,
            "description": description,
            "createdAt": createdAt.firestoreTimestamp,
            "startDate": startDate.firestoreTimestamp,
            "endDate": endDate.firestoreTimestamp,
            "isFeatured": isFeatured,
            "registrationRequired": registrationRequired,
            "authorId": author.id,
            "hostId": host.id
        ]
        
        // Add optional fields
        if let mediaItems = mediaItems, !mediaItems.isEmpty {
            data["mediaItems"] = mediaItems.map { $0.toFirestoreData() }
        }
        
        if let registrationLink = registrationLink {
            data["registrationLink"] = registrationLink
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let authorId = firestoreData["authorId"] as? String,
            let hostId = firestoreData["hostId"] as? String,
            let name = firestoreData["name"] as? String,
            let typeRawValue = firestoreData["type"] as? String,
            let type = EventType(rawValue: typeRawValue),
            let location = firestoreData["location"] as? String,
            let description = firestoreData["description"] as? String
        else {
            print("DEBUG: Failed to decode required EventItem fields")
            print("DEBUG: Available keys: \(firestoreData.keys.sorted())")
            return nil
        }
        
        // Handle timestamps
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let startDate: Date
        if let timestamp = firestoreData["startDate"] as? Timestamp {
            startDate = timestamp.dateValue()
        } else if let timestamp = firestoreData["eventDate"] as? Timestamp {
            // Handle legacy eventDate field for backward compatibility
            startDate = timestamp.dateValue()
        } else {
            startDate = Date().addingTimeInterval(24 * 60 * 60) // Default to tomorrow
        }
        
        let endDate: Date
        if let timestamp = firestoreData["endDate"] as? Timestamp {
            endDate = timestamp.dateValue()
        } else {
            // Default endDate to be the same as startDate if not provided
            endDate = startDate
        }
        
        // Handle boolean values
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        let registrationRequired = firestoreData["registrationRequired"] as? Bool ?? false
        
        // Handle optional fields
        let registrationLink = firestoreData["registrationLink"] as? String
        
        // Handle media items
        var mediaItems: [MediaItem]?
        if let mediaItemsData = firestoreData["mediaItems"] as? [[String: Any]] {
            let decodedMediaItems = mediaItemsData.compactMap { MediaItem(firestoreData: $0) }
            mediaItems = decodedMediaItems.isEmpty ? nil : decodedMediaItems
        }
        
        // Create placeholder objects for author and host
        // These will be replaced with actual objects by the repository
        let placeholderAuthor = User.placeholder(id: authorId)
        let placeholderHost = Gym.placeholder(id: hostId)
        
        self.init(
            id: id,
            author: placeholderAuthor,
            host: placeholderHost,
            name: name,
            type: type,
            location: location,
            description: description,
            mediaItems: mediaItems,
            registrationLink: registrationLink,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            isFeatured: isFeatured,
            registrationRequired: registrationRequired
        )
    }
}
    
// MARK: - Firebase Event Repository Implementation

class FirebaseEventRepository: EventRepositoryProtocol {
    private let db = Firestore.firestore()
    private let eventsCollection = "events"
    private let usersCollection = "users"
    private let gymsCollection = "gyms"
    
    private let userRepository: UserRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         gymRepository: GymRepositoryProtocol = FirebaseGymRepository(),
         mediaRepository: MediaRepositoryProtocol = FirebaseMediaRepository()) {
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
            print("DEBUG: Error: Document data is nil for \(document.documentID)")
            return nil
        }
        
        // Add the ID to the data
        data["id"] = document.documentID
        
        // Get required IDs for related entities
        guard
            let authorId = data["authorId"] as? String,
            let hostId = data["hostId"] as? String
        else {
            print("DEBUG: Missing author or host ID in document \(document.documentID)")
            return nil
        }
        
        do {
            // Fetch related entities with better error handling
            let author: User?
            let host: Gym?
            
            do {
                author = try await userRepository.getUser(id: authorId)
                if author == nil {
                    print("DEBUG: Author not found with ID: \(authorId)")
                }
            } catch {
                print("DEBUG: Error fetching author \(authorId): \(error.localizedDescription)")
                author = nil
            }
            
            do {
                host = try await gymRepository.getGym(id: hostId)
                if host == nil {
                    print("DEBUG: Gym not found with ID: \(hostId)")
                }
            } catch {
                print("DEBUG: Error fetching gym \(hostId): \(error.localizedDescription)")
                host = nil
            }
            
            if let author = author, let host = host {
                return EventItem(firestoreData: data)
            } else {
                // Only log this if we're using the fallback
                print("DEBUG: Using placeholder implementation for event \(document.documentID)")
                return EventItem(firestoreData: data)
            }
        } catch {
            print("DEBUG: Unexpected error in decodeEvent: \(error.localizedDescription)")
            return EventItem(firestoreData: data)
        }
    }
}
