//
//  FirebaseMediaRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 27/05/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore
import FirebaseAuth
import UIKit

class FirebaseMediaRepository: MediaRepositoryProtocol {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let mediaCollection = "media"
    
    init() {
        // Log Firebase Storage configuration
        print("📱 Firebase Storage initialized")
        print("📱 Storage URL: \(storage.reference().bucket)")
        
        // Check if Firebase is properly configured
        if FirebaseApp.app() != nil {
            print("✅ Firebase app is configured")
        } else {
            print("❌ Firebase app is not configured")
        }
    }
    
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
            print("📤 Starting Firebase Storage upload for file: \(fileName), size: \(data.count) bytes")
            
            // Check authentication state first
            if let currentUser = Auth.auth().currentUser {
                print("✅ User authenticated: \(currentUser.uid)")
                print("✅ User email: \(currentUser.email ?? "no email")")
                print("✅ User is anonymous: \(currentUser.isAnonymous)")
            } else {
                print("❌ No authenticated user found!")
                throw MediaError.uploadFailed
            }
            
            // Test Firebase Storage connection
            let storageRef = storage.reference()
            print("✅ Firebase Storage reference created successfully")
            print("✅ Storage bucket: \(storageRef.bucket)")
            
            // Create storage reference
            let mediaRef = storageRef.child("media/\(ownerId)/\(fileName)")
            print("✅ Storage path: media/\(ownerId)/\(fileName)")
    
            // Upload data to Firebase Storage
            let metadata = StorageMetadata()
            metadata.contentType = determineContentType(from: fileName)
            print("✅ Content type set to: \(metadata.contentType ?? "unknown")")
            
            print("🔄 Starting upload to Firebase Storage...")
            let uploadResult = try await mediaRef.putDataAsync(data, metadata: metadata)
            print("✅ Upload completed. Size: \(uploadResult.size) bytes")
            
            // Get download URL
            print("🔄 Getting download URL...")
            let downloadURL = try await mediaRef.downloadURL()
            print("✅ Download URL obtained: \(downloadURL)")
            
            // Create MediaItem object
            let mediaItem = MediaItem(
                id: UUID().uuidString,
                url: downloadURL,
                type: determineMediaType(from: fileName),
                uploadedAt: Date(),
                ownerId: ownerId
            )
            
            // Save metadata to Firestore
            print("🔄 Saving metadata to Firestore...")
            try await saveMediaMetadata(mediaItem)
            print("✅ Metadata saved successfully")
            
            return mediaItem
            
        } catch {
            // Log the actual error for debugging
            print("❌ Firebase media upload failed: \(error)")
            if let storageError = error as NSError? {
                print("❌ Storage error details: \(storageError.localizedDescription)")
                print("❌ Storage error code: \(storageError.code)")
                print("❌ Storage error domain: \(storageError.domain)")
                print("❌ Storage error user info: \(storageError.userInfo)")
                
                // Check for specific unauthorized error
                if storageError.domain.contains("FIRStorageErrorDomain") && storageError.code == 403 {
                    print("❌ This is a Firebase Storage authorization error!")
                    print("❌ Possible causes:")
                    print("   1. Firebase Storage rules don't allow authenticated users to write")
                    print("   2. User token has expired")
                    print("   3. Firebase Storage is not properly configured")
                }
            }
            
            // Throw the original error instead of generic one
            throw error
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
