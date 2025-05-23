//
//  MediaFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation
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

// Optional: Add a Repository class for MediaItem if you need CRUD operations

class FirebaseMediaRepository {
    private let db = Firestore.firestore()
    private let mediaCollection = "media"
    
    func uploadMedia(_ media: MediaItem) async throws -> String {
        var mediaData = media.toFirestoreData()
        
        // Remove id from data if Firestore should generate one
        if media.id.isEmpty {
            mediaData.removeValue(forKey: "id")
        }
        
        let documentReference: DocumentReference
        if media.id.isEmpty {
            // Let Firestore generate an ID
            documentReference = try await db.collection(mediaCollection).addDocument(data: mediaData)
            return documentReference.documentID
        } else {
            // Use the provided ID
            try await db.collection(mediaCollection).document(media.id).setData(mediaData)
            return media.id
        }
    }
    
    func getMedia(id: String) async throws -> MediaItem? {
        let documentSnapshot = try await db.collection(mediaCollection).document(id).getDocument()
        
        if documentSnapshot.exists, let data = documentSnapshot.data() {
            var mediaData = data
            mediaData["id"] = documentSnapshot.documentID
            return MediaItem(firestoreData: mediaData)
        }
        
        return nil
    }
    
    func deleteMedia(id: String) async throws {
        try await db.collection(mediaCollection).document(id).delete()
    }
    
    func getMediaForOwner(ownerId: String) async throws -> [MediaItem] {
        let snapshot = try await db.collection(mediaCollection)
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document -> MediaItem? in
            var data = document.data()
            data["id"] = document.documentID
            return MediaItem(firestoreData: data)
        }
    }
}
