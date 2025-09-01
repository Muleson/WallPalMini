//
//  CachedGymRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation
import UIKit

/// Cached decorator for GymRepositoryProtocol that adds memory caching
final class CachedGymRepository: GymRepositoryProtocol {
    
    // MARK: - Private Properties
    
    private let baseRepository: GymRepositoryProtocol
    private let cache: MemoryCache<Gym>
    private let searchCache: MemoryCache<[String]>
    
    // MARK: - Initialization
    
    init(baseRepository: GymRepositoryProtocol, 
         cache: MemoryCache<Gym>? = nil,
         searchCache: MemoryCache<[String]>? = nil) {
        self.baseRepository = baseRepository
        self.cache = cache ?? CacheManager.shared.gymCache
        self.searchCache = searchCache ?? CacheManager.shared.searchCache
    }
    
    // MARK: - GymRepositoryProtocol Implementation
    
    func fetchAllGyms() async throws -> [Gym] {
        let cacheKey = CacheManager.CacheKeys.allGyms()
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedGyms = cachedIds.compactMap { cache.get(forKey: CacheManager.CacheKeys.gymById($0)) }
            
            // Only return cached result if we have all gyms
            if cachedGyms.count == cachedIds.count {
                print("🎯 Cache hit: fetchAllGyms (\(cachedGyms.count) gyms)")
                return cachedGyms
            }
        }
        
        print("🌐 Cache miss: fetchAllGyms - fetching from source")
        
        // Fetch from base repository
        let gyms = try await baseRepository.fetchAllGyms()
        
        // Cache individual gyms and the list of IDs
        let gymIds = gyms.map { gym in
            cache.set(gym, forKey: CacheManager.CacheKeys.gymById(gym.id))
            return gym.id
        }
        
        searchCache.set(gymIds, forKey: cacheKey)
        
        print("💾 Cached \(gyms.count) gyms")
        return gyms
    }
    
    func searchGyms(query: String) async throws -> [Gym] {
        let cacheKey = CacheManager.CacheKeys.gymSearch(query)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedGyms = cachedIds.compactMap { cache.get(forKey: CacheManager.CacheKeys.gymById($0)) }
            
            // Only return cached result if we have all gyms
            if cachedGyms.count == cachedIds.count {
                print("🎯 Cache hit: searchGyms('\(query)') - \(cachedGyms.count) results")
                return cachedGyms
            }
        }
        
        print("🌐 Cache miss: searchGyms('\(query)') - fetching from source")
        
        // Fetch from base repository
        let gyms = try await baseRepository.searchGyms(query: query)
        
        // Cache individual gyms and the search result IDs
        let gymIds = gyms.map { gym in
            cache.set(gym, forKey: CacheManager.CacheKeys.gymById(gym.id))
            return gym.id
        }
        
        searchCache.set(gymIds, forKey: cacheKey)
        
        print("💾 Cached search result for '\(query)': \(gyms.count) gyms")
        return gyms
    }
    
    func getGym(id: String) async throws -> Gym? {
        let cacheKey = CacheManager.CacheKeys.gymById(id)
        
        // Try cache first
        if let cachedGym = cache.get(forKey: cacheKey) {
            print("🎯 Cache hit: getGym(\(id))")
            return cachedGym
        }
        
        print("🌐 Cache miss: getGym(\(id)) - fetching from source")
        
        // Fetch from base repository
        let gym = try await baseRepository.getGym(id: id)
        
        // Cache the result if found
        if let gym = gym {
            cache.set(gym, forKey: cacheKey)
            print("💾 Cached gym: \(gym.name)")
        }
        
        return gym
    }
    
    func getGyms(ids: [String]) async throws -> [Gym] {
        var result: [Gym] = []
        var uncachedIds: [String] = []
        
        // First, try to get from cache
        for id in ids {
            let cacheKey = CacheManager.CacheKeys.gymById(id)
            if let cachedGym = cache.get(forKey: cacheKey) {
                result.append(cachedGym)
            } else {
                uncachedIds.append(id)
            }
        }
        
        // If we have everything cached, return early
        if uncachedIds.isEmpty {
            print("🎯 Cache hit: getGyms (all \(ids.count) gyms cached)")
            return result
        }
        
        print("🌐 Partial cache miss: getGyms - \(uncachedIds.count)/\(ids.count) need fetching")
        
        // Fetch uncached gyms from base repository
        let uncachedGyms = try await baseRepository.getGyms(ids: uncachedIds)
        
        // Cache the newly fetched gyms
        for gym in uncachedGyms {
            cache.set(gym, forKey: CacheManager.CacheKeys.gymById(gym.id))
            result.append(gym)
        }
        
        print("💾 Cached \(uncachedGyms.count) additional gyms")
        return result
    }
    
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws {
        // Delegate to base repository
        try await baseRepository.updateUserFavoriteGyms(userId: userId, favoritedGymIds: favoritedGymIds)
        
        // No need to invalidate gym cache as this doesn't change gym data
        // But we might want to invalidate user cache if we cached user favorites
        print("✅ Updated user favorite gyms for user: \(userId)")
    }
    
    func createGym(_ gym: Gym, ownerId: String) async throws -> Gym {
        // Create in base repository
        let createdGym = try await baseRepository.createGym(gym, ownerId: ownerId)
        
        // Cache the new gym
        cache.set(createdGym, forKey: CacheManager.CacheKeys.gymById(createdGym.id))
        
        // Invalidate list caches since we have new data
        searchCache.removeAll()
        
        print("💾 Cached newly created gym: \(createdGym.name)")
        return createdGym
    }
    
    func updateGym(_ gym: Gym) async throws -> Gym {
        // Update in base repository
        let updatedGym = try await baseRepository.updateGym(gym)
        
        // Update cache with new data
        cache.set(updatedGym, forKey: CacheManager.CacheKeys.gymById(updatedGym.id))
        
        // Invalidate search caches since gym data changed
        searchCache.removeAll()
        
        print("💾 Updated cached gym: \(updatedGym.name)")
        return updatedGym
    }
    
    func updateGymImage(gymId: String, image: UIImage) async throws -> URL {
        // Update in base repository
        let imageURL = try await baseRepository.updateGymImage(gymId: gymId, image: image)
        
        // Invalidate the specific gym cache so it gets refreshed with new image data
        cache.remove(forKey: CacheManager.CacheKeys.gymById(gymId))
        
        print("🖼️ Invalidated cache for gym \(gymId) due to image update")
        return imageURL
    }
    
    func deleteGym(id: String) async throws {
        // Delete from base repository
        try await baseRepository.deleteGym(id: id)
        
        // Remove from cache
        cache.remove(forKey: CacheManager.CacheKeys.gymById(id))
        
        // Invalidate list caches
        searchCache.removeAll()
        
        print("🗑️ Removed gym \(id) from cache")
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // This method searches for users, not gyms, so we don't cache it in gym cache
        // We delegate directly to the base repository
        return try await baseRepository.searchUsers(query: query)
    }
    
    func updateGymVerificationStatus(gymId: String, status: GymVerificationStatus, notes: String?, verifiedBy: String?) async throws -> Gym {
        // Update in base repository
        let updatedGym = try await baseRepository.updateGymVerificationStatus(
            gymId: gymId, 
            status: status, 
            notes: notes, 
            verifiedBy: verifiedBy
        )
        
        // Update cache with new verification data
        cache.set(updatedGym, forKey: CacheManager.CacheKeys.gymById(updatedGym.id))
        
        // Invalidate search caches since verification status might affect search results
        searchCache.removeAll()
        
        print("🔒 Updated verification status for gym: \(gymId)")
        return updatedGym
    }
    
    func getGymsByVerificationStatus(_ status: GymVerificationStatus) async throws -> [Gym] {
        // For verification status queries, we don't cache since this is typically an admin function
        // and we want fresh data
        print("🔒 Fetching gyms by verification status (not cached): \(status)")
        return try await baseRepository.getGymsByVerificationStatus(status)
    }
}

// MARK: - Cache Management Extension

extension CachedGymRepository {
    
    /// Clear all cached gym data
    func clearCache() {
        cache.removeAll()
        searchCache.removeAll()
        
        #if DEBUG
        print("🗑️ Cleared all gym cache data")
        #endif
    }
    
    #if DEBUG
    /// Print cache status for debugging
    func printCacheStatus() {
        print("🏋️ Gym Cache: \(cache.count) items")
        print("🔍 Gym Search Cache: \(searchCache.count) results")
    }
    #endif
}
