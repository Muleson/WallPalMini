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
            "eventType": eventType.rawValue,
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
        if let climbingType = climbingType, !climbingType.isEmpty {
            data["climbingType"] = climbingType.map { $0.rawValue }
        }
        
        if let mediaItems = mediaItems, !mediaItems.isEmpty {
            data["mediaItems"] = mediaItems.map { $0.toFirestoreData() }
        }
        
        if let registrationLink = registrationLink {
            data["registrationLink"] = registrationLink
        }
        
        if let frequency = frequency {
            data["frequency"] = frequency.rawValue
        }
        
        if let recurrenceEndDate = recurrenceEndDate {
            data["recurrenceEndDate"] = recurrenceEndDate.firestoreTimestamp
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let authorId = firestoreData["authorId"] as? String,
            let hostId = firestoreData["hostId"] as? String,
            let name = firestoreData["name"] as? String,
            let location = firestoreData["location"] as? String,
            let description = firestoreData["description"] as? String
        else {
            return nil
        }
        
        // Handle eventType with backward compatibility for "type" field
        let eventType: EventType
        if let eventTypeRawValue = firestoreData["eventType"] as? String,
           let type = EventType(rawValue: eventTypeRawValue) {
            eventType = type
        } else if let typeRawValue = firestoreData["type"] as? String,
                  let type = EventType(rawValue: typeRawValue) {
            // Backward compatibility for old "type" field
            eventType = type
        } else {
            return nil
        }
        
        // Handle climbingType array
        var climbingType: [ClimbingTypes]?
        if let climbingTypeRawValues = firestoreData["climbingType"] as? [String] {
            climbingType = climbingTypeRawValues.compactMap { ClimbingTypes(rawValue: $0) }
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
        
        // Handle frequency
        var frequency: EventFrequency?
        if let frequencyRawValue = firestoreData["frequency"] as? String {
            frequency = EventFrequency(rawValue: frequencyRawValue)
        }
        
        // Handle recurrence end date
        var recurrenceEndDate: Date?
        if let timestamp = firestoreData["recurrenceEndDate"] as? Timestamp {
            recurrenceEndDate = timestamp.dateValue()
        }
        
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
            eventType: eventType,
            climbingType: climbingType,
            location: location,
            description: description,
            mediaItems: mediaItems,
            registrationLink: registrationLink,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            isFeatured: isFeatured,
            registrationRequired: registrationRequired,
            frequency: frequency,
            recurrenceEndDate: recurrenceEndDate
        )
    }
}
