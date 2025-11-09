//
//  MediaColorService.swift
//  GriGriMVP
//
//  Service for extracting and caching prominent colors from event media
//

import SwiftUI
import UIKit

/// Service for managing color extraction from media items with caching
@MainActor
class MediaColorService: ObservableObject {
    static let shared = MediaColorService()

    /// Cache for storing extracted colors by media URL
    private var colorCache: [String: Color] = [:]

    /// Currently loading URLs to prevent duplicate work
    private var loadingURLs: Set<String> = []

    private init() {}

    /// Get the prominent color for a media item
    /// - Parameters:
    ///   - mediaItem: The media item to extract color from
    ///   - fallbackColor: Color to return if extraction fails or is still loading
    /// - Returns: The prominent color or fallback color
    func getColor(for mediaItem: MediaItem?, fallback fallbackColor: Color) -> Color {
        guard let mediaItem = mediaItem else {
            return fallbackColor
        }

        let cacheKey = mediaItem.url.absoluteString

        // Return cached color if available
        if let cachedColor = colorCache[cacheKey] {
            return cachedColor
        }

        // Return fallback if currently loading
        if loadingURLs.contains(cacheKey) {
            return fallbackColor
        }

        // Start extraction asynchronously
        Task {
            await extractAndCacheColor(for: mediaItem, fallback: fallbackColor)
        }

        return fallbackColor
    }

    /// Extract color from a media item and cache it
    /// - Parameters:
    ///   - mediaItem: The media item to extract color from
    ///   - fallbackColor: Color to use if extraction fails
    private func extractAndCacheColor(for mediaItem: MediaItem, fallback fallbackColor: Color) async {
        let cacheKey = mediaItem.url.absoluteString

        // Check if already loading or cached
        if loadingURLs.contains(cacheKey) || colorCache[cacheKey] != nil {
            return
        }

        loadingURLs.insert(cacheKey)

        do {
            // Download image data
            let (data, _) = try await URLSession.shared.data(from: mediaItem.url)

            guard let uiImage = UIImage(data: data) else {
                await MainActor.run {
                    colorCache[cacheKey] = fallbackColor
                    loadingURLs.remove(cacheKey)
                }
                return
            }

            // Extract color on background thread
            let extractedColor = await Task.detached {
                ColorExtractor.extractProminentColor(from: uiImage, options: .fast)
            }.value

            await MainActor.run {
                colorCache[cacheKey] = extractedColor ?? fallbackColor
                loadingURLs.remove(cacheKey)
                // Trigger UI update by publishing change
                self.objectWillChange.send()
            }

        } catch {
            print("Failed to extract color from media: \(error.localizedDescription)")
            await MainActor.run {
                colorCache[cacheKey] = fallbackColor
                loadingURLs.remove(cacheKey)
            }
        }
    }

    /// Preload color for a media item (useful for prefetching)
    /// - Parameters:
    ///   - mediaItem: The media item to preload color for
    ///   - fallbackColor: Color to use if extraction fails
    func preloadColor(for mediaItem: MediaItem?, fallback fallbackColor: Color) {
        guard let mediaItem = mediaItem else { return }

        let cacheKey = mediaItem.url.absoluteString

        // Skip if already cached or loading
        if colorCache[cacheKey] != nil || loadingURLs.contains(cacheKey) {
            return
        }

        Task {
            await extractAndCacheColor(for: mediaItem, fallback: fallbackColor)
        }
    }

    /// Clear the color cache
    func clearCache() {
        colorCache.removeAll()
        loadingURLs.removeAll()
    }

    /// Remove a specific color from cache
    /// - Parameter mediaItem: The media item whose color should be removed
    func removeFromCache(mediaItem: MediaItem) {
        let cacheKey = mediaItem.url.absoluteString
        colorCache.removeValue(forKey: cacheKey)
    }
}

// MARK: - View Extension for Convenience

extension View {
    /// Get the prominent color for a media item with a fallback
    func mediaColor(for mediaItem: MediaItem?, fallback: Color) -> Color {
        MediaColorService.shared.getColor(for: mediaItem, fallback: fallback)
    }
}
