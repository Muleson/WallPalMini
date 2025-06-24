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
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": createdAt.firestoreTimestamp
        ]
        
        // Note: Don't include 'id' in the data - Firestore handles document IDs separately
        
        // Add optional fields if they exist
        if let favoriteGyms = favoriteGyms {
            data["favouriteGyms"] = favoriteGyms
        }
        
        if let favoriteEvents = favoriteEvents {
            data["favouriteEvents"] = favoriteEvents
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
            print("DEBUG: Failed to decode required User fields")
            print("DEBUG: Available keys: \(firestoreData.keys.sorted())")
            return nil
        }
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        // Handle optional properties (note the spelling difference)
        let favoriteGyms = firestoreData["favouriteGyms"] as? [String]
        let favoriteEvents = firestoreData["favouriteEvents"] as? [String]
        
        self.init(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            createdAt: createdAt,
            favoriteGyms: favoriteGyms,
            favoriteEvents: favoriteEvents
        )
    }
}

extension UserFavorite: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "eventId": eventId,
            "dateAdded": dateAdded.firestoreTimestamp
        ]
        // Note: Don't include 'id' in the data - Firestore handles document IDs separately
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let userId = firestoreData["userId"] as? String,
            let eventId = firestoreData["eventId"] as? String
        else {
            print("DEBUG: Failed to decode required UserFavorite fields")
            return nil
        }
        
        let dateAdded: Date
        if let timestamp = firestoreData["dateAdded"] as? Timestamp {
            dateAdded = timestamp.dateValue()
        } else {
            dateAdded = Date()
        }
        
        self.init(
            id: id,
            userId: userId,
            eventId: eventId,
            dateAdded: dateAdded
        )
    }
}
