//
//  UserFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import FirebaseFirestore

extension User: FirestoreCodable {
    // Convert User to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": createdAt.firestoreTimestamp
        ]
        return data
    }
    
    // Initialize a User from Firestore data
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let email = firestoreData["email"] as? String,
            let firstName = firestoreData["firstName"] as? String,
            let lastName = firestoreData["lastName"] as? String
        else {
            // Return nil if required fields are missing
            return nil
        }
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()  // Default to current date if missing
        }
        
        // Initialize User
        self.init(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            createdAt: createdAt,
            favouriteGyms: nil
        )
    }
}
