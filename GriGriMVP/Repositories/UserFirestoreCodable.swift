//
//  UserFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import FirebaseFirestore

extension User: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": createdAt.firestoreTimestamp
        ]
        
        // Add optional fields if they exist
        if let favouriteGyms = favoriteGyms {
            data["favouriteGyms"] = favouriteGyms
        }
        
        if let favouriteEvents = favoriteEvents {
            data["favouriteEvents"] = favouriteEvents
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let email = firestoreData["email"] as? String,
            let firstName = firestoreData["firstName"] as? String,
            let lastName = firestoreData["lastName"] as? String
        else {
            return nil
        }
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        // Handle optional properties
        let favouriteGyms = firestoreData["favouriteGyms"] as? [String]
        let favouriteEvents = firestoreData["favouriteEvents"] as? [String]
        
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.favoriteGyms = favouriteGyms
        self.favoriteEvents = favouriteEvents
    }
}

extension UserFavorite: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "eventId": eventId,
            "dateAdded": dateAdded.firestoreTimestamp
        ]
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let userId = firestoreData["userId"] as? String,
            let eventId = firestoreData["eventId"] as? String
        else {
            return nil
        }
        
        let dateAdded: Date
        if let timestamp = firestoreData["dateAdded"] as? Timestamp {
            dateAdded = timestamp.dateValue
        } else {
            dateAdded = Date()
        }
        
        self.id = id
        self.userId = userId
        self.eventId = eventId
        self.dateAdded = dateAdded
    }
}
