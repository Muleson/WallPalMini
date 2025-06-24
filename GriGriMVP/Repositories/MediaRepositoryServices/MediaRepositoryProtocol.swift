//
//  MediaRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 27/05/2025.
//

import Foundation
import UIKit

protocol MediaRepositoryProtocol {
    /// Upload an image to Firebase Storage and save metadata to Firestore
    func uploadImage(_ image: UIImage, ownerId: String, compressionQuality: CGFloat) async throws -> MediaItem
    
    /// Upload data to Firebase Storage and save metadata to Firestore
    func uploadData(_ data: Data, ownerId: String, fileName: String) async throws -> MediaItem
    
    /// Get media item by ID
    func getMedia(id: String) async throws -> MediaItem?
    
    /// Get all media for a specific owner
    func getMediaForOwner(ownerId: String) async throws -> [MediaItem]
    
    /// Delete media item (both from Storage and Firestore)
    func deleteMedia(_ mediaItem: MediaItem) async throws
    
    /// Get download URL for a media item
    func getDownloadURL(for mediaItem: MediaItem) async throws -> URL
}


