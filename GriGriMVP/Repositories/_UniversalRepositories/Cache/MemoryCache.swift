//
//  MemoryCache.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation

/// Thread-safe in-memory cache with LRU eviction and automatic cleanup
public final class MemoryCache<T> {
    
    // MARK: - Private Properties
    
    private let queue = DispatchQueue(label: "com.grigri.cache.\(T.self)", attributes: .concurrent)
    private var storage: [String: CachedItem<T>] = [:]
    private var accessOrder: [String] = [] // For LRU tracking
    private var cleanupTimer: Timer?
    
    // Configuration
    private let defaultTimeToLive: TimeInterval
    private let maxSize: Int
    private let cleanupInterval: TimeInterval
    
    // MARK: - Public Properties
    
    /// Current number of items in the cache
    public var count: Int {
        return queue.sync { storage.count }
    }
    
    /// All keys currently in the cache
    public var keys: [String] {
        return queue.sync { Array(storage.keys) }
    }
    
    // MARK: - Initialization
    
    /// Initialize a new memory cache
    /// - Parameters:
    ///   - defaultTimeToLive: Default TTL for cached items (in seconds)
    ///   - maxSize: Maximum number of items to store (LRU eviction when exceeded)
    ///   - cleanupInterval: How often to run automatic cleanup (in seconds)
    public init(
        defaultTimeToLive: TimeInterval = 3600, // 1 hour default
        maxSize: Int = 1000,
        cleanupInterval: TimeInterval = 300 // 5 minutes default
    ) {
        self.defaultTimeToLive = defaultTimeToLive
        self.maxSize = maxSize
        self.cleanupInterval = cleanupInterval
        
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Cache Operations
    
    /// Store a value in the cache with default TTL
    /// - Parameters:
    ///   - value: The value to cache
    ///   - key: The key to store the value under
    public func set(_ value: T, forKey key: String) {
        set(value, forKey: key, timeToLive: defaultTimeToLive)
    }
    
    /// Store a value in the cache with custom TTL
    /// - Parameters:
    ///   - value: The value to cache
    ///   - key: The key to store the value under
    ///   - timeToLive: Custom TTL for this item (in seconds)
    public func set(_ value: T, forKey key: String, timeToLive: TimeInterval) {
        queue.async(flags: .barrier) {
            let cachedItem = CachedItem(value: value, timeToLive: timeToLive)
            
            // Remove from access order if it already exists
            if let existingIndex = self.accessOrder.firstIndex(of: key) {
                self.accessOrder.remove(at: existingIndex)
            }
            
            // Add to storage and mark as most recently used
            self.storage[key] = cachedItem
            self.accessOrder.append(key)
            
            // Enforce size limit using LRU eviction
            self.enforceSizeLimit()
        }
    }
    
    /// Retrieve a value from the cache
    /// - Parameter key: The key to look up
    /// - Returns: The cached value if it exists and hasn't expired, nil otherwise
    public func get(forKey key: String) -> T? {
        return queue.sync(flags: .barrier) {
            guard let cachedItem = self.storage[key] else {
                return nil
            }
            
            // Check if expired
            if cachedItem.isExpired {
                self.storage.removeValue(forKey: key)
                if let index = self.accessOrder.firstIndex(of: key) {
                    self.accessOrder.remove(at: index)
                }
                return nil
            }
            
            // Update access order (move to end = most recently used)
            if let index = self.accessOrder.firstIndex(of: key) {
                self.accessOrder.remove(at: index)
                self.accessOrder.append(key)
            }
            
            return cachedItem.value
        }
    }
    
    /// Remove a specific item from the cache
    /// - Parameter key: The key to remove
    /// - Returns: The removed value if it existed
    @discardableResult
    public func remove(forKey key: String) -> T? {
        return queue.sync(flags: .barrier) {
            let removedItem = self.storage.removeValue(forKey: key)
            if let index = self.accessOrder.firstIndex(of: key) {
                self.accessOrder.remove(at: index)
            }
            
            return removedItem?.value
        }
    }
    
    /// Remove all items from the cache
    public func removeAll() {
        queue.async(flags: .barrier) {
            self.storage.removeAll()
            self.accessOrder.removeAll()
        }
    }
    
    /// Check if a key exists in the cache (and hasn't expired)
    /// - Parameter key: The key to check
    /// - Returns: true if the key exists and hasn't expired
    public func contains(key: String) -> Bool {
        return get(forKey: key) != nil
    }
    
    // MARK: - Cache Management
    
    /// Manually trigger cleanup of expired items
    /// - Returns: Number of items removed
    @discardableResult
    public func cleanupExpiredItems() -> Int {
        return queue.sync(flags: .barrier) {
            var removedCount = 0
            
            // Find expired keys
            let expiredKeys = self.storage.compactMap { (key, cachedItem) in
                return cachedItem.isExpired ? key : nil
            }
            
            // Remove expired items
            for key in expiredKeys {
                self.storage.removeValue(forKey: key)
                if let index = self.accessOrder.firstIndex(of: key) {
                    self.accessOrder.remove(at: index)
                }
                removedCount += 1
            }
            
            #if DEBUG
            if removedCount > 0 {
                print("🧹 Cache cleanup: removed \(removedCount) expired items")
            }
            #endif
            
            return removedCount
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// Get information about cache contents (for debugging)
    public func debugInfo() -> [String: Any] {
        return queue.sync {
            return [
                "count": storage.count,
                "maxSize": maxSize,
                "defaultTTL": defaultTimeToLive,
                "oldestKey": accessOrder.first ?? "none",
                "newestKey": accessOrder.last ?? "none"
            ]
        }
    }
    
    /// Print cache status
    public func printStatus() {
        let info = debugInfo()
        print("🔍 Cache Status: \(info["count"] ?? 0)/\(maxSize) items")
    }
    #endif
    
    // MARK: - Private Methods
    
    private func enforceSizeLimit() {
        // This method should be called within a barrier block
        var evictedCount = 0
        while storage.count > maxSize && !accessOrder.isEmpty {
            // Remove least recently used item (first in access order)
            let lruKey = accessOrder.removeFirst()
            storage.removeValue(forKey: lruKey)
            evictedCount += 1
        }
        
        #if DEBUG
        if evictedCount > 0 {
            print("📤 Cache evicted \(evictedCount) LRU items")
        }
        #endif
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            self?.cleanupExpiredItems()
        }
    }
}

// MARK: - Convenience Methods

extension MemoryCache {
    /// Set multiple values at once
    /// - Parameter items: Dictionary of key-value pairs to cache
    public func setMultiple(_ items: [String: T]) {
        for (key, value) in items {
            set(value, forKey: key)
        }
    }
    
    /// Get multiple values at once
    /// - Parameter keys: Array of keys to retrieve
    /// - Returns: Dictionary of found key-value pairs
    public func getMultiple(forKeys keys: [String]) -> [String: T] {
        var result: [String: T] = [:]
        for key in keys {
            if let value = get(forKey: key) {
                result[key] = value
            }
        }
        return result
    }
}
