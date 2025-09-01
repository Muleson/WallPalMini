//
//  CacheManager.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation

/// Centralized cache manager for all repository caches
public final class CacheManager {
    
    // MARK: - Singleton
    
    public static let shared = CacheManager()
    
    // MARK: - Cache Instances
    
    /// Cache for Gym entities (6 hour TTL)
    let gymCache: MemoryCache<Gym>
    
    /// Cache for Event entities (2 hour TTL)  
    let eventCache: MemoryCache<EventItem>
    
    /// Cache for User entities (30 minute TTL)
    let userCache: MemoryCache<User>
    
    /// Cache for search results (15 minute TTL)
    public let searchCache: MemoryCache<[String]>
    
    // MARK: - Configuration Constants
    
    private struct CacheConfig {
        // TTL values in seconds
        static let gymTTL: TimeInterval = 6 * 60 * 60      // 6 hours
        static let eventTTL: TimeInterval = 2 * 60 * 60    // 2 hours  
        static let userTTL: TimeInterval = 30 * 60         // 30 minutes
        static let searchTTL: TimeInterval = 15 * 60       // 15 minutes
        
        // Size limits
        static let gymMaxSize = 500
        static let eventMaxSize = 1000
        static let userMaxSize = 200
        static let searchMaxSize = 100
        
        // Cleanup intervals
        static let cleanupInterval: TimeInterval = 5 * 60  // 5 minutes
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize caches with appropriate TTL and size limits
        self.gymCache = MemoryCache<Gym>(
            defaultTimeToLive: CacheConfig.gymTTL,
            maxSize: CacheConfig.gymMaxSize,
            cleanupInterval: CacheConfig.cleanupInterval
        )
        
        self.eventCache = MemoryCache<EventItem>(
            defaultTimeToLive: CacheConfig.eventTTL,
            maxSize: CacheConfig.eventMaxSize,
            cleanupInterval: CacheConfig.cleanupInterval
        )
        
        self.userCache = MemoryCache<User>(
            defaultTimeToLive: CacheConfig.userTTL,
            maxSize: CacheConfig.userMaxSize,
            cleanupInterval: CacheConfig.cleanupInterval
        )
        
        self.searchCache = MemoryCache<[String]>(
            defaultTimeToLive: CacheConfig.searchTTL,
            maxSize: CacheConfig.searchMaxSize,
            cleanupInterval: CacheConfig.cleanupInterval
        )
        
        #if DEBUG
        print("📱 CacheManager initialized - Gym: \(CacheConfig.gymTTL/3600)h, Event: \(CacheConfig.eventTTL/3600)h, User: \(CacheConfig.userTTL/60)m")
        #endif
    }
    
    // MARK: - Cache Management
    
    /// Clear all caches
    public func clearAllCaches() {
        gymCache.removeAll()
        eventCache.removeAll()
        userCache.removeAll()
        searchCache.removeAll()
        
        #if DEBUG
        print("🗑️ All caches cleared")
        #endif
    }
    
    /// Cleanup expired items in all caches
    /// - Returns: Total number of items removed across all caches
    @discardableResult
    public func cleanupAllCaches() -> Int {
        let gymCleanup = gymCache.cleanupExpiredItems()
        let eventCleanup = eventCache.cleanupExpiredItems()
        let userCleanup = userCache.cleanupExpiredItems()
        let searchCleanup = searchCache.cleanupExpiredItems()
        
        let totalCleaned = gymCleanup + eventCleanup + userCleanup + searchCleanup
        
        #if DEBUG
        if totalCleaned > 0 {
            print("🧹 Cache cleanup removed \(totalCleaned) expired items")
        }
        #endif
        
        return totalCleaned
    }
    
    #if DEBUG
    /// Print cache status for debugging
    public func printCacheStatus() {
        print("""
        📊 Cache Status:
        🏋️ Gyms: \(gymCache.count)/\(CacheConfig.gymMaxSize) items
        📅 Events: \(eventCache.count)/\(CacheConfig.eventMaxSize) items  
        👤 Users: \(userCache.count)/\(CacheConfig.userMaxSize) items
        🔍 Search: \(searchCache.count)/\(CacheConfig.searchMaxSize) items
        """)
    }
    #endif
    
    // MARK: - Cache Invalidation Helpers
    
    /// Invalidate cache entries related to a specific gym
    /// - Parameter gymId: ID of the gym to invalidate
    public func invalidateGymRelatedData(gymId: String) {
        // Remove the gym itself
        gymCache.remove(forKey: CacheKeys.gymById(gymId))
        
        // Invalidate related search results
        searchCache.removeAll() // Simple approach - clear all search cache
        
        #if DEBUG
        print("🚫 Invalidated cache for gym: \(gymId)")
        #endif
    }
    
    /// Invalidate cache entries related to a specific event
    /// - Parameter eventId: ID of the event to invalidate
    public func invalidateEventRelatedData(eventId: String) {
        // Remove the event itself
        eventCache.remove(forKey: CacheKeys.eventById(eventId))
        
        // Invalidate related search results
        searchCache.removeAll() // Simple approach - clear all search cache
        
        #if DEBUG
        print("🚫 Invalidated cache for event: \(eventId)")
        #endif
    }
    
    /// Invalidate cache entries related to a specific user
    /// - Parameter userId: ID of the user to invalidate
    public func invalidateUserRelatedData(userId: String) {
        // Remove the user itself
        userCache.remove(forKey: CacheKeys.userById(userId))
        
        #if DEBUG
        print("🚫 Invalidated cache for user: \(userId)")
        #endif
    }
}

// MARK: - Cache Key Helpers

extension CacheManager {
    
    /// Generate cache keys for different types of queries
    public struct CacheKeys {
        
        // Gym cache keys
        public static func gymById(_ id: String) -> String {
            return "gym:\(id)"
        }
        
        public static func gymsByIds(_ ids: [String]) -> String {
            return "gyms:\(ids.sorted().joined(separator:","))"
        }
        
        public static func allGyms() -> String {
            return "gyms:all"
        }
        
        public static func gymSearch(_ query: String) -> String {
            return "gyms:search:\(query.lowercased())"
        }
        
        // Event cache keys
        public static func eventById(_ id: String) -> String {
            return "event:\(id)"
        }
        
        public static func allEvents() -> String {
            return "events:all"
        }
        
        public static func eventsForGym(_ gymId: String) -> String {
            return "events:gym:\(gymId)"
        }
        
        public static func eventsForUser(_ userId: String) -> String {
            return "events:user:\(userId)"
        }
        
        public static func favoriteEvents(_ userId: String) -> String {
            return "events:favorites:\(userId)"
        }
        
        public static func eventSearch(_ query: String) -> String {
            return "events:search:\(query.lowercased())"
        }
        
        public static func sectionEvents(_ section: String) -> String {
            return "events:section:\(section)"
        }
        
        // User cache keys
        public static func userById(_ id: String) -> String {
            return "user:\(id)"
        }
        
        public static func currentUser() -> String {
            return "user:current"
        }
        
        public static func userSearch(_ query: String) -> String {
            return "users:search:\(query.lowercased())"
        }
    }
}
