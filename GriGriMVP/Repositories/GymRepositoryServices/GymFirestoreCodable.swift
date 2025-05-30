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
            "createdAt": createdAt.firestoreTimestamp,
            "ownerId": ownerId,
            "staffUserIds": staffUserIds,
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        if let profileImage = profileImage {
            data["profileImage"] = [
                "id": profileImage.id,
                "url": profileImage.url.absoluteString,
                "type": profileImage.type.rawValue,
                "uploadedAt": profileImage.uploadedAt.firestoreTimestamp,
                "ownerId": profileImage.ownerId
            ]
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
            let events = firestoreData["events"] as? [String],
            let ownerId = firestoreData["ownerId"] as? String
        else {
            return nil
        }
        
        // Convert climbing type strings back to enum
        let climbingTypes = climbingTypeStrings.compactMap { ClimbingTypes(rawValue: $0) }
        
        // Handle optional description
        let description = firestoreData["description"] as? String
        
        // Parse MediaItem from nested data
        let profileImage: MediaItem?
        if let imageData = firestoreData["profileImage"] as? [String: Any],
           let imageId = imageData["id"] as? String,
           let imageUrlString = imageData["url"] as? String,
           let imageUrl = URL(string: imageUrlString),
           let imageTypeString = imageData["type"] as? String,
           let imageType = MediaType(rawValue: imageTypeString),
           let imageOwnerId = imageData["ownerId"] as? String {
            
            let uploadedAt: Date
            if let timestamp = imageData["uploadedAt"] as? Timestamp {
                uploadedAt = timestamp.dateValue
            } else {
                uploadedAt = Date()
            }
            
            profileImage = MediaItem(
                id: imageId,
                url: imageUrl,
                type: imageType,
                uploadedAt: uploadedAt,
                ownerId: imageOwnerId
            )
        } else {
            profileImage = nil
        }
        
        // Handle staff user IDs array (default to empty if missing)
        let staffUserIds = firestoreData["staffUserIds"] as? [String] ?? []
        
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()
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
            profileImage: profileImage,
            createdAt: createdAt,
            ownerId: ownerId,
            staffUserIds: staffUserIds,
        )
    }
}
