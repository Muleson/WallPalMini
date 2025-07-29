//
//  LocalMediaRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import Foundation
import PhotosUI

class LocalMediaRepository: MediaRepositoryProtocol {
    private var mediaItems = SampleData.mediaItems
    
    // Your actual asset names from Preview Assets
    private let gymLogoAssets = ["SampleLogo1", "SampleLogo2", "SampleLogo3", "SampleLogo4"]
    private let eventPosterAssets = ["SamplePoster1", "SamplePoster2", "SamplePoster3", "SamplePoster4", "SamplePoster5"]
    
    func uploadImage(_ image: UIImage, ownerId: String, compressionQuality: CGFloat) async throws -> MediaItem {
        // Determine if this is for a gym or event based on ownerId pattern
        let assetName: String
        if ownerId.hasPrefix("gym") {
            assetName = gymLogoAssets.randomElement() ?? "SampleLogo1"
        } else {
            assetName = eventPosterAssets.randomElement() ?? "SamplePoster1"
        }
        
        let newMediaItem = MediaItem(
            id: UUID().uuidString,
            url: URL(string: "local-asset://\(assetName)")!,
            type: .image,
            uploadedAt: Date(),
            ownerId: ownerId
        )
        mediaItems.append(newMediaItem)
        return newMediaItem
    }
    
    func uploadData(_ data: Data, ownerId: String, fileName: String) async throws -> MediaItem {
        // Similar logic for data uploads
        let assetName = gymLogoAssets.randomElement() ?? "SampleLogo1"
        let newMediaItem = MediaItem(
            id: UUID().uuidString,
            url: URL(string: "local-asset://\(assetName)")!,
            type: .image,
            uploadedAt: Date(),
            ownerId: ownerId
        )
        mediaItems.append(newMediaItem)
        return newMediaItem
    }
    
    func getMedia(id: String) async throws -> MediaItem? {
        return mediaItems.first { $0.id == id }
    }
    
    func getMediaForOwner(ownerId: String) async throws -> [MediaItem] {
        return mediaItems.filter { $0.ownerId == ownerId }
    }
    
    func deleteMedia(_ mediaItem: MediaItem) async throws {
        mediaItems.removeAll { $0.id == mediaItem.id }
        print("Deleted local media: \(mediaItem.id)")
    }
    
    func getDownloadURL(for mediaItem: MediaItem) async throws -> URL {
        return mediaItem.url
    }
}
