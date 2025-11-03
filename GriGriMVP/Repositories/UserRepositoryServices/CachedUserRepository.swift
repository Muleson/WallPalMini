//
//  CachedUserRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation

/// Cached decorator for UserRepositoryProtocol that adds memory caching
final class CachedUserRepository: UserRepositoryProtocol {
    
    // MARK: - Private Properties
    
    private let baseRepository: UserRepositoryProtocol
    private let cache: MemoryCache<User>
    private let searchCache: MemoryCache<[String]>
    
    // MARK: - Initialization
    
    init(baseRepository: UserRepositoryProtocol,
         cache: MemoryCache<User>? = nil,
         searchCache: MemoryCache<[String]>? = nil) {
        self.baseRepository = baseRepository
        self.cache = cache ?? CacheManager.shared.userCache
        self.searchCache = searchCache ?? CacheManager.shared.searchCache
    }
    
    // MARK: - Authentication Methods (Not Cached)
    
    func signIn(email: String, password: String) async throws -> User {
        // Authentication methods are not cached for security reasons
        let user = try await baseRepository.signIn(email: email, password: password)
        
        // Cache the authenticated user
        cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
        cache.set(user, forKey: CacheManager.CacheKeys.currentUser())
        
        print("💾 Cached authenticated user: \(user.firstName) \(user.lastName)")
        return user
    }
    
    func createUser(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        // User creation is not cached
        let user = try await baseRepository.createUser(email: email, password: password, firstName: firstName, lastName: lastName)
        
        // Cache the newly created user
        cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
        cache.set(user, forKey: CacheManager.CacheKeys.currentUser())
        
        print("💾 Cached newly created user: \(user.firstName) \(user.lastName)")
        return user
    }
    
    func signOut() throws {
        // Clear current user cache on sign out
        cache.remove(forKey: CacheManager.CacheKeys.currentUser())
        
        // Delegate to base repository
        try baseRepository.signOut()
        
        print("🗑️ Cleared current user cache on sign out")
    }
    
    func getCurrentAuthUser() -> String? {
        // Authentication state is not cached - always delegate to base repository
        return baseRepository.getCurrentAuthUser()
    }
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
        // Apple sign in is not cached
        let user = try await baseRepository.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName)
        
        // Cache the authenticated user
        cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
        cache.set(user, forKey: CacheManager.CacheKeys.currentUser())
        
        print("💾 Cached Apple sign-in user: \(user.firstName) \(user.lastName)")
        return user
    }
    
    // MARK: - User Data Methods (Cached)
    
    func getUser(id: String) async throws -> User? {
        let cacheKey = CacheManager.CacheKeys.userById(id)
        
        // Try cache first
        if let cachedUser = cache.get(forKey: cacheKey) {
            print("🎯 Cache hit: getUser(\(id))")
            return cachedUser
        }
        
        print("🌐 Cache miss: getUser(\(id)) - fetching from source")
        
        // Fetch from base repository
        let user = try await baseRepository.getUser(id: id)
        
        // Cache the result if found
        if let user = user {
            cache.set(user, forKey: cacheKey)
            print("💾 Cached user: \(user.firstName) \(user.lastName)")
        }
        
        return user
    }
    
    func getCurrentUser() async throws -> User? {
        let cacheKey = CacheManager.CacheKeys.currentUser()
        
        // Try cache first
        if let cachedUser = cache.get(forKey: cacheKey) {
            print("🎯 Cache hit: getCurrentUser()")
            return cachedUser
        }
        
        print("🌐 Cache miss: getCurrentUser() - fetching from source")
        
        // Fetch from base repository
        let user = try await baseRepository.getCurrentUser()
        
        // Cache the result if found
        if let user = user {
            cache.set(user, forKey: cacheKey)
            cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
            print("💾 Cached current user: \(user.firstName) \(user.lastName)")
        }
        
        return user
    }
    
    func updateUser(_ user: User) async throws {
        // Update in base repository
        try await baseRepository.updateUser(user)
        
        // Update cache with new data
        cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
        
        // Update current user cache if this is the current user
        if let currentAuthUserId = getCurrentAuthUser(), currentAuthUserId == user.id {
            cache.set(user, forKey: CacheManager.CacheKeys.currentUser())
        }
        
        print("💾 Updated cached user: \(user.firstName) \(user.lastName)")
    }
    
    // MARK: - Favorite Management Methods
    
    func updateUserFavoriteGyms(userId: String, gymId: String, isFavorite: Bool) async throws -> [String] {
        // Update in base repository
        let updatedFavoriteGymIds = try await baseRepository.updateUserFavoriteGyms(userId: userId, gymId: gymId, isFavorite: isFavorite)
        
        // Invalidate user cache so updated favorites are fetched next time
        cache.remove(forKey: CacheManager.CacheKeys.userById(userId))
        
        // Also invalidate current user cache if this is the current user
        if let currentAuthUserId = getCurrentAuthUser(), currentAuthUserId == userId {
            cache.remove(forKey: CacheManager.CacheKeys.currentUser())
        }
        
        print("🚫 Invalidated user cache for \(userId) due to favorite gym update")
        return updatedFavoriteGymIds
    }
    
    func updateUserFavoriteEvents(userId: String, eventId: String, isFavorite: Bool) async throws -> [String] {
        // Update in base repository
        let updatedFavoriteEventIds = try await baseRepository.updateUserFavoriteEvents(userId: userId, eventId: eventId, isFavorite: isFavorite)

        // Invalidate user cache so updated favorites are fetched next time
        cache.remove(forKey: CacheManager.CacheKeys.userById(userId))

        // Also invalidate current user cache if this is the current user
        if let currentAuthUserId = getCurrentAuthUser(), currentAuthUserId == userId {
            cache.remove(forKey: CacheManager.CacheKeys.currentUser())
        }

        // IMPORTANT: Invalidate the favorite events cache so SavedEventsView gets fresh data
        searchCache.remove(forKey: CacheManager.CacheKeys.favoriteEvents(userId))

        print("🚫 Invalidated user cache and favorite events cache for \(userId) due to favorite event update")
        return updatedFavoriteEventIds
    }
}

// MARK: - Batch Operations

extension CachedUserRepository {
    
    /// Get multiple users by their IDs (with caching)
    func getUsers(ids: [String]) async throws -> [User] {
        var result: [User] = []
        var uncachedIds: [String] = []
        
        // First, try to get from cache
        for id in ids {
            let cacheKey = CacheManager.CacheKeys.userById(id)
            if let cachedUser = cache.get(forKey: cacheKey) {
                result.append(cachedUser)
            } else {
                uncachedIds.append(id)
            }
        }
        
        // If we have everything cached, return early
        if uncachedIds.isEmpty {
            print("🎯 Cache hit: getUsers (all \(ids.count) users cached)")
            return result
        }
        
        print("🌐 Partial cache miss: getUsers - \(uncachedIds.count)/\(ids.count) need fetching")
        
        // Fetch uncached users individually (since UserRepository doesn't have batch get)
        for id in uncachedIds {
            if let user = try await baseRepository.getUser(id: id) {
                cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
                result.append(user)
            }
        }
        
        print("💾 Cached \(uncachedIds.count) additional users")
        return result
    }
}

// MARK: - Cache Management Extension

extension CachedUserRepository {
    
    /// Clear all cached user data
    func clearCache() {
        cache.removeAll()
        searchCache.removeAll()
        
        #if DEBUG
        print("🗑️ Cleared all user cache data")
        #endif
    }
    
    /// Clear only current user cache (useful for testing or forced refresh)
    func clearCurrentUserCache() {
        cache.remove(forKey: CacheManager.CacheKeys.currentUser())
        
        #if DEBUG
        print("🗑️ Cleared current user cache")
        #endif
    }
    
    /// Refresh current user data (force fetch from source)
    func refreshCurrentUser() async throws -> User? {
        // Clear current user cache
        clearCurrentUserCache()
        
        // Fetch fresh data
        return try await getCurrentUser()
    }
    
    /// Pre-cache a user (useful for optimization)
    func precacheUser(_ user: User) {
        cache.set(user, forKey: CacheManager.CacheKeys.userById(user.id))
        
        #if DEBUG
        print("💾 Pre-cached user: \(user.firstName) \(user.lastName)")
        #endif
    }
    
    #if DEBUG
    /// Print cache status for debugging
    func printCacheStatus() {
        print("👤 User Cache: \(cache.count) items")
        print("🔍 User Search Cache: \(searchCache.count) results")
    }
    #endif
}
