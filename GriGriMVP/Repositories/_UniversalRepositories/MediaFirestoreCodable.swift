//
//  MediaFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import FirebaseFirestore

extension MediaItem: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        let data: [String: Any] = [
            "id": id,
            "url": url.absoluteString,
            "type": type.rawValue,
            "uploadedAt": uploadedAt.firestoreTimestamp,
            "ownerId": ownerId
        ]
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let urlString = firestoreData["url"] as? String,
            let url = URL(string: urlString),
            let typeRawValue = firestoreData["type"] as? String,
            let type = MediaType(rawValue: typeRawValue),
            let uploadedAtTimestamp = firestoreData["uploadedAt"] as? Timestamp,
            let ownerId = firestoreData["ownerId"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.url = url
        self.type = type
        self.uploadedAt = uploadedAtTimestamp.dateValue
        self.ownerId = ownerId
    }
}
