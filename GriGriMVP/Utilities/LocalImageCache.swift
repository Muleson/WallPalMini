//
//  LocalImageCache.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/09/2025.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Cache Metadata

struct CachedImageMetadata: Codable {
    let downloadedAt: Date
    let fileSize: Int64
    var lastAccessedAt: Date

    var age: TimeInterval {
        Date().timeIntervalSince(downloadedAt)
    }
}

// MARK: - Cache Error

enum CacheError: Error, LocalizedError {
    case downloadFailed(URL, Error)
    case corruptedData(String)
    case diskFull
    case invalidImage
    case imageTooLarge(Int64)

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let url, let error):
            return "Failed to download image from \(url): \(error.localizedDescription)"
        case .corruptedData(let id):
            return "Corrupted image data for ID: \(id)"
        case .diskFull:
            return "Disk cache is full"
        case .invalidImage:
            return "Invalid or corrupted image file"
        case .imageTooLarge(let size):
            return "Image too large: \(size) bytes (max 5MB)"
        }
    }
}

// MARK: - Cache Stats

struct CacheStats {
    let totalImages: Int
    let totalDiskSize: Int64
    let oldestImageAge: TimeInterval?
    let memoryCount: Int
}

@MainActor
class LocalImageCache: ObservableObject {
    static let shared = LocalImageCache()

    // MARK: - Properties

    // Memory cache with NSCache for automatic memory management
    private let imageCache = NSCache<NSString, UIImage>()

    // Metadata for tracking cache entries
    private var metadata: [String: CachedImageMetadata] = [:]

    // Active downloads tracking
    private var activeDownloads: Set<String> = []

    // File management
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataFileURL: URL

    // Configuration constants
    private let maxMemoryCount = 100 // Max images in memory
    private let maxMemorySize = 50_000_000 // 50MB memory budget
    private let maxDiskSize: Int64 = 100_000_000 // 100MB disk budget
    private let maxImageSize: Int64 = 5_000_000 // 5MB per image
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    private init() {
        // Create cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("GymImageCache")
        metadataFileURL = cacheDirectory.appendingPathComponent("metadata.json")

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure NSCache limits
        imageCache.countLimit = maxMemoryCount
        imageCache.totalCostLimit = maxMemorySize
        imageCache.name = "com.grigri.gymImageCache"

        // Load metadata and cache asynchronously
        Task {
            await loadMetadata()
            await loadCachedImagesAsync()
            await invalidateExpired()
        }
    }
    
    // MARK: - Public Methods

    /// Get cached image for the given ID (gym or company)
    /// Updates last accessed time if image is found
    func getCachedImage(for id: String) -> UIImage? {
        // Check if expired
        if let meta = metadata[id], meta.age > cacheTTL {
            Task {
                await invalidateImage(for: id)
            }
            return nil
        }

        // Try memory cache first
        if let image = imageCache.object(forKey: id as NSString) {
            // Update last accessed time
            updateLastAccessed(for: id)
            return image
        }

        // Try disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(id).jpg")
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // Load into memory cache
        let cost = estimateImageCost(image)
        imageCache.setObject(image, forKey: id as NSString, cost: cost)
        updateLastAccessed(for: id)

        return image
    }

    /// Cache image with retry logic and validation
    func cacheImage(for id: String, from url: URL, retryCount: Int = 0) async -> Result<Void, CacheError> {
        // Check if already cached
        if imageCache.object(forKey: id as NSString) != nil {
            return .success(())
        }

        // Check if we're already downloading this image
        if activeDownloads.contains(id) {
            return .success(())
        }

        activeDownloads.insert(id)
        defer { activeDownloads.remove(id) }

        do {
            // Download image data
            let (data, response) = try await URLSession.shared.data(from: url)

            // Validate size
            let dataSize = Int64(data.count)
            guard dataSize <= maxImageSize else {
                return .failure(.imageTooLarge(dataSize))
            }

            // Validate image
            guard let image = UIImage(data: data),
                  image.size.width > 0,
                  image.size.height > 0 else {
                return .failure(.invalidImage)
            }

            // Check disk space before writing
            let currentSize = await calculateTotalDiskSize()
            if currentSize + dataSize > maxDiskSize {
                // Evict old images to make space
                await evictLRUImages(targetSize: maxDiskSize - dataSize)
            }

            // Compress and write to disk
            let fileURL = cacheDirectory.appendingPathComponent("\(id).jpg")
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                return .failure(.invalidImage)
            }

            try jpegData.write(to: fileURL)

            // Cache in memory
            let cost = estimateImageCost(image)
            imageCache.setObject(image, forKey: id as NSString, cost: cost)

            // Save metadata
            let meta = CachedImageMetadata(
                downloadedAt: Date(),
                fileSize: Int64(jpegData.count),
                lastAccessedAt: Date()
            )
            metadata[id] = meta
            await saveMetadata()

            return .success(())

        } catch {
            // Retry logic with exponential backoff
            if retryCount < 3 {
                let delay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return await cacheImage(for: id, from: url, retryCount: retryCount + 1)
            }

            return .failure(.downloadFailed(url, error))
        }
    }

    /// Invalidate a single image
    func invalidateImage(for id: String) async {
        imageCache.removeObject(forKey: id as NSString)
        metadata.removeValue(forKey: id)

        let fileURL = cacheDirectory.appendingPathComponent("\(id).jpg")
        try? fileManager.removeItem(at: fileURL)

        await saveMetadata()
    }

    /// Invalidate all expired images
    func invalidateExpired() async {
        let now = Date()
        let expiredIds = metadata.filter { $0.value.age > cacheTTL }.map { $0.key }

        for id in expiredIds {
            await invalidateImage(for: id)
        }

        if !expiredIds.isEmpty {
            print("🗑️ LocalImageCache: Removed \(expiredIds.count) expired images")
        }
    }

    /// Clear entire cache
    func clearCache() {
        imageCache.removeAllObjects()
        metadata.removeAll()
        activeDownloads.removeAll()

        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        print("🗑️ LocalImageCache: Cache cleared")
    }

    /// Get cache statistics
    var cacheStats: CacheStats {
        let totalImages = metadata.count
        let totalDiskSize = metadata.values.reduce(0) { $0 + $1.fileSize }
        let oldestImageAge = metadata.values.map { $0.age }.max()

        // Estimate memory count (NSCache doesn't expose this directly)
        let memoryCount = metadata.keys.filter { imageCache.object(forKey: $0 as NSString) != nil }.count

        return CacheStats(
            totalImages: totalImages,
            totalDiskSize: totalDiskSize,
            oldestImageAge: oldestImageAge,
            memoryCount: memoryCount
        )
    }

    /// Print cache statistics for debugging
    func printCacheStats() {
        let stats = cacheStats
        print("""
        📊 LocalImageCache Stats:
        - Total images: \(stats.totalImages)
        - Disk size: \(formatBytes(stats.totalDiskSize))
        - Memory images: \(stats.memoryCount)
        - Oldest image: \(stats.oldestImageAge.map { formatTimeInterval($0) } ?? "N/A")
        """)
    }

    // MARK: - Private Methods

    /// Load cached images asynchronously from disk
    private func loadCachedImagesAsync() async {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            )

            // Filter out metadata file
            let imageFiles = files.filter { $0.lastPathComponent != "metadata.json" }

            print("📦 LocalImageCache: Found \(imageFiles.count) cached images on disk")

            // Don't load all images into memory - they'll be loaded on demand
            // Just validate they exist

        } catch {
            print("⚠️ LocalImageCache: Failed to load cached images: \(error)")
        }
    }

    /// Load metadata from disk
    private func loadMetadata() async {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            // Migrate from old cache format if needed
            await migrateLegacyCache()
            return
        }

        do {
            let data = try Data(contentsOf: metadataFileURL)
            metadata = try JSONDecoder().decode([String: CachedImageMetadata].self, from: data)
            print("📦 LocalImageCache: Loaded metadata for \(metadata.count) images")
        } catch {
            print("⚠️ LocalImageCache: Failed to load metadata: \(error)")
            await migrateLegacyCache()
        }
    }

    /// Save metadata to disk
    private func saveMetadata() async {
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataFileURL)
        } catch {
            print("⚠️ LocalImageCache: Failed to save metadata: \(error)")
        }
    }

    /// Migrate from old cache format (no metadata)
    private func migrateLegacyCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            )

            for file in files where file.pathExtension == "jpg" {
                let id = file.deletingPathExtension().lastPathComponent

                // Get file attributes
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let modDate = attributes[.modificationDate] as? Date ?? Date()

                metadata[id] = CachedImageMetadata(
                    downloadedAt: modDate,
                    fileSize: fileSize,
                    lastAccessedAt: Date()
                )
            }

            await saveMetadata()
            print("✅ LocalImageCache: Migrated \(metadata.count) legacy cache entries")

        } catch {
            print("⚠️ LocalImageCache: Failed to migrate legacy cache: \(error)")
        }
    }

    /// Update last accessed time for an image
    private func updateLastAccessed(for id: String) {
        guard var meta = metadata[id] else { return }
        meta.lastAccessedAt = Date()
        metadata[id] = meta

        // Persist metadata periodically (not on every access for performance)
        // Could batch these updates
    }

    /// Calculate total disk size used by cache
    private func calculateTotalDiskSize() async -> Int64 {
        return metadata.values.reduce(0) { $0 + $1.fileSize }
    }

    /// Evict least recently used images until target size is reached
    private func evictLRUImages(targetSize: Int64) async {
        let currentSize = await calculateTotalDiskSize()
        guard currentSize > targetSize else { return }

        // Sort by last accessed time (oldest first)
        let sortedIds = metadata.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }

        var evictedSize: Int64 = 0
        var evictedCount = 0

        for (id, meta) in sortedIds {
            await invalidateImage(for: id)
            evictedSize += meta.fileSize
            evictedCount += 1

            if currentSize - evictedSize <= targetSize {
                break
            }
        }

        print("🗑️ LocalImageCache: Evicted \(evictedCount) images (\(formatBytes(evictedSize))) via LRU")
    }

    /// Estimate memory cost of an image for NSCache
    private func estimateImageCost(_ image: UIImage) -> Int {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return width * height * 4 // 4 bytes per pixel (RGBA)
    }

    /// Format bytes for human-readable output
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Format time interval for human-readable output
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval / (24 * 60 * 60))
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        let hours = Int(interval / (60 * 60))
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
}
