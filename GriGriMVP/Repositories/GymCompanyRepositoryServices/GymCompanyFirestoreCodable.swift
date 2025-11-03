//
//  GymCompanyFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/10/2025.
//

import Foundation
import FirebaseFirestore

extension GymCompany: FirestoreCodable {
    // Convert GymCompany to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "createdAt": createdAt.firestoreTimestamp
        ]

        // Add optional fields if they exist
        if let description = description {
            data["description"] = description
        }

        if let profileImage = profileImage {
            data["profileImage"] = profileImage.toFirestoreData()
        }

        if let gymIds = gymIds {
            data["gymIds"] = gymIds
        }

        if let email = email {
            data["email"] = email
        }

        if let website = website {
            data["website"] = website
        }

        return data
    }

    // Initialize a GymCompany from Firestore data
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let name = firestoreData["name"] as? String
        else {
            print("DEBUG: Failed to decode required GymCompany fields")
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

        // Handle optional fields
        let description = firestoreData["description"] as? String

        // Handle profile image
        let profileImage: MediaItem?
        if let imageData = firestoreData["profileImage"] as? [String: Any] {
            profileImage = MediaItem(firestoreData: imageData)
        } else {
            profileImage = nil
        }

        let gymIds = firestoreData["gymIds"] as? [String]
        let email = firestoreData["email"] as? String
        let website = firestoreData["website"] as? String

        // Initialize with structure
        self.init(
            id: id,
            name: name,
            description: description,
            profileImage: profileImage,
            createdAt: createdAt,
            gymIds: gymIds,
            email: email,
            website: website
        )
    }
}
