//
//  FirebaseMediaRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 27/05/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FirebaseMediaRepository: MediaRepositoryProtocol {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let mediaCollection = "media"
    
    // MARK: - Upload Methods
    
    func uploadImage(_ image: UIImage, ownerId: String, compressionQuality: CGFloat = 0.8) async throws -> MediaItem {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw MediaError.imageConversionFailed
        }
        
        // Generate unique filename
        let fileName = "\(UUID().uuidString).jpg"
        
        return try await uploadData(imageData, ownerId: ownerId, fileName: fileName)
    }
    
    func uploadData(_ data: Data, ownerId: String, fileName: String) async throws -> MediaItem {
        do {
            // Create storage reference
            let storageRef = storage.reference()
            let mediaRef = storageRef.child("media/\(ownerId)/\(fileName)")
    
            
            // Upload data to Firebase Storage
            let metadata = StorageMetadata()
            metadata.contentType = determineContentType(from: fileName)
            
            let uploadResult = try await mediaRef.putDataAsync(data, metadata: metadata)
            
            // Get download URL
            let downloadURL = try await mediaRef.downloadURL()
            
            // Create MediaItem object
            let mediaItem = MediaItem(
                id: UUID().uuidString,
                url: downloadURL,
                type: determineMediaType(from: fileName),
                uploadedAt: Date(),
                ownerId: ownerId
            )
            
            // Save metadata to Firestore
            try await saveMediaMetadata(mediaItem)
            
            return mediaItem
            
        } catch {
            if let storageError = error as NSError? {
            }
            
            throw MediaError.uploadFailed
        }
    }
    
    // MARK: - Retrieval Methods
    
    func getMedia(id: String) async throws -> MediaItem? {
        let documentSnapshot = try await db.collection(mediaCollection).document(id).getDocument()
        
        if documentSnapshot.exists, let data = documentSnapshot.data() {
            var mediaData = data
            mediaData["id"] = documentSnapshot.documentID
            return MediaItem(firestoreData: mediaData)
        }
        
        return nil
    }
    
    func getMediaForOwner(ownerId: String) async throws -> [MediaItem] {
        let snapshot = try await db.collection(mediaCollection)
            .whereField("ownerId", isEqualTo: ownerId)
            .order(by: "uploadedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> MediaItem? in
            var data = document.data()
            data["id"] = document.documentID
            return MediaItem(firestoreData: data)
        }
    }
    
    // MARK: - Deletion Methods
    
    func deleteMedia(_ mediaItem: MediaItem) async throws {
        // Extract path from URL
        guard let path = extractStoragePath(from: mediaItem.url) else {
            throw MediaError.invalidStoragePath
        }
        
        // Delete from Storage
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
        
        // Delete from Firestore
        try await db.collection(mediaCollection).document(mediaItem.id).delete()
    }
    
    // MARK: - URL Methods
    
    func getDownloadURL(for mediaItem: MediaItem) async throws -> URL {
        // If the URL is still valid, return it
        if isURLValid(mediaItem.url) {
            return mediaItem.url
        }
        
        // Otherwise, fetch a fresh URL from Storage
        guard let path = extractStoragePath(from: mediaItem.url) else {
            throw MediaError.invalidStoragePath
        }
        
        let storageRef = storage.reference().child(path)
        let newURL = try await storageRef.downloadURL()
        
        // Update the URL in Firestore
        try await db.collection(mediaCollection).document(mediaItem.id).updateData([
            "url": newURL.absoluteString
        ])
        
        return newURL
    }
    
    // MARK: - Private Helper Methods
    
    private func saveMediaMetadata(_ mediaItem: MediaItem) async throws {
        let mediaData = mediaItem.toFirestoreData()
        try await db.collection(mediaCollection).document(mediaItem.id).setData(mediaData)
    }
    
    private func determineContentType(from fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "heic":
            return "image/heic"
        default:
            return "application/octet-stream"
        }
    }
    
    private func determineMediaType(from fileName: String) -> MediaType {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "heic":
            return .image
        default:
            return .none
        }
    }
    
    private func extractStoragePath(from url: URL) -> String? {
        // Firebase Storage URLs contain the path after "/o/"
        let urlString = url.absoluteString
        
        guard let range = urlString.range(of: "/o/") else { return nil }
        
        let pathWithToken = String(urlString[range.upperBound...])
        
        // Remove the token part (everything after "?")
        if let questionMarkRange = pathWithToken.range(of: "?") {
            let path = String(pathWithToken[..<questionMarkRange.lowerBound])
            // Decode URL encoding
            return path.removingPercentEncoding
        }
        
        return pathWithToken.removingPercentEncoding
    }
    
    private func isURLValid(_ url: URL) -> Bool {
        // Simple check - you might want to implement more sophisticated validation
        // For now, we'll assume URLs are valid for 7 days
        return true
    }
}

// MARK: - Media Error Enum
enum MediaError: LocalizedError {
    case imageConversionFailed
    case invalidStoragePath
    case uploadFailed
    case deletionFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .invalidStoragePath:
            return "Invalid storage path"
        case .uploadFailed:
            return "Failed to upload media"
        case .deletionFailed:
            return "Failed to delete media"
        }
    }
}
