//
//  GymFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/05/2025.
//

import Foundation
import FirebaseFirestore

extension Gym: FirestoreCodable {
    // Convert Gym to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "email": email,
            "location": location.toFirestoreData(),
            "climbingType": climbingType.map { $0.rawValue },
            "amenities": amenities.map { $0.rawValue },
            "events": events,
            "ownerId": ownerId,
            "staffUserIds": staffUserIds,
            "createdAt": createdAt.firestoreTimestamp,
            "verificationStatus": verificationStatus.rawValue
        ]
        
        // Add optional fields if they exist
        if let description = description {
            data["description"] = description
        }
        
        if let profileImage = profileImage {
            data["profileImage"] = profileImage.toFirestoreData()
        }
        
        if let verificationNotes = verificationNotes {
            data["verificationNotes"] = verificationNotes
        }
        
        if let verifiedAt = verifiedAt {
            data["verifiedAt"] = verifiedAt.firestoreTimestamp
        }
        
        if let verifiedBy = verifiedBy {
            data["verifiedBy"] = verifiedBy
        }
        
        return data
    }
    
    // Initialize a Gym from Firestore data
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let name = firestoreData["name"] as? String,
            let email = firestoreData["email"] as? String,
            let ownerId = firestoreData["ownerId"] as? String,
            let locationData = firestoreData["location"] as? [String: Any]
        else {
            print("DEBUG: Failed to decode required Gym fields")
            print("DEBUG: Available keys: \(firestoreData.keys.sorted())")
            return nil
        }
        
        // Handle location
        guard let location = LocationData(firestoreData: locationData) else {
            print("DEBUG: Failed to decode location data")
            return nil
        }
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        // Handle climbing types
        let climbingTypeStrings = firestoreData["climbingType"] as? [String] ?? []
        let climbingType = climbingTypeStrings.compactMap { ClimbingTypes(rawValue: $0) }
        
        // Handle amenities
        let amenityStrings = firestoreData["amenities"] as? [String] ?? []
        let amenities = amenityStrings.compactMap { Amenities(rawValue: $0) }
        
        // Handle other fields
        let description = firestoreData["description"] as? String
        let events = firestoreData["events"] as? [String] ?? []
        let staffUserIds = firestoreData["staffUserIds"] as? [String] ?? []
        
        // Handle profile image
        var profileImage: MediaItem?
        if let imageData = firestoreData["profileImage"] as? [String: Any] {
            profileImage = MediaItem(firestoreData: imageData)
        }
        
        // Handle verification status
        let verificationStatusString = firestoreData["verificationStatus"] as? String ?? "pending"
        let verificationStatus = GymVerificationStatus(rawValue: verificationStatusString) ?? .pending
        
        // Handle verification notes
        let verificationNotes = firestoreData["verificationNotes"] as? String
        
        // Handle verifiedAt timestamp
        var verifiedAt: Date?
        if let timestamp = firestoreData["verifiedAt"] as? Timestamp {
            verifiedAt = timestamp.dateValue()
        }
        
        // Handle verifiedBy
        let verifiedBy = firestoreData["verifiedBy"] as? String
        
        self.init(
            id: id,
            email: email,
            name: name,
            description: description,
            location: location,
            climbingType: climbingType,
            amenities: amenities,
            events: events,
            profileImage: profileImage,
            createdAt: createdAt,
            ownerId: ownerId,
            staffUserIds: staffUserIds,
            verificationStatus: verificationStatus,
            verificationNotes: verificationNotes,
            verifiedAt: verifiedAt,
            verifiedBy: verifiedBy
        )
    }
}
