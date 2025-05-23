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
            "email": email,
            "name": name,
            "location": [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address ?? ""
            ],
            "climbingType": climbingType.map { $0.rawValue },
            "amenities": amenities,
            "events": events,
            "createdAt": createdAt.firestoreTimestamp
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        if let imageUrl = imageUrl {
            data["imageUrl"] = imageUrl.absoluteString
        }
        
        return data
    }
    
    // Initialize a Gym from Firestore data
    init?(firestoreData: [String: Any]) {
        guard
            let email = firestoreData["email"] as? String,
            let name = firestoreData["name"] as? String,
            let locationData = firestoreData["location"] as? [String: Any],
            let latitude = locationData["latitude"] as? Double,
            let longitude = locationData["longitude"] as? Double,
            let climbingTypeStrings = firestoreData["climbingType"] as? [String],
            let amenities = firestoreData["amenities"] as? [String],
            let events = firestoreData["events"] as? [String]
        else {
            // Return nil if required fields are missing
            return nil
        }
        
        // Convert climbing type strings back to enum
        let climbingTypes = climbingTypeStrings.compactMap { ClimbingTypes(rawValue: $0) }
        
        // Handle optional description
        let description = firestoreData["description"] as? String
        
        // Handle optional image URL
        let imageUrl: URL?
        if let imageUrlString = firestoreData["imageUrl"] as? String, !imageUrlString.isEmpty {
            imageUrl = URL(string: imageUrlString)
        } else {
            imageUrl = nil
        }
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()  // Default to current date if missing
        }
        
        // Handle optional address (check for empty string too)
        let address = locationData["address"] as? String
        let finalAddress = (address?.isEmpty == true) ? nil : address
        
        let location = LocationData(
            latitude: latitude,
            longitude: longitude,
            address: finalAddress
        )
        
        // Initialize Gym with a temporary ID (will be set by repository)
        self.init(
            id: UUID().uuidString,
            email: email,
            name: name,
            description: description,
            location: location,
            climbingType: climbingTypes,
            amenities: amenities,
            events: events,
            imageUrl: imageUrl,
            createdAt: createdAt
        )
    }
}
