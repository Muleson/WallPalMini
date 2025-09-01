//
//  CacheTest.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation

#if DEBUG
/// Simple cache testing utilities for development
struct CacheTest {
    
    /// Test basic cache functionality with sample data
    static func runBasicTest() {
        print("🧪 Running Basic Cache Test")
        print("==========================")
        
        let cache = MemoryCache<String>(defaultTimeToLive: 60, maxSize: 5)
        
        // Test set and get
        cache.set("Hello World", forKey: "greeting")
        if let value = cache.get(forKey: "greeting") {
            print("✅ Set/Get: \(value)")
        }
        
        // Test cache miss
        if cache.get(forKey: "nonexistent") == nil {
            print("✅ Cache Miss: Key not found as expected")
        }
        
        // Test multiple items
        for i in 1...3 {
            cache.set("Value \(i)", forKey: "key\(i)")
        }
        
        print("✅ Cache now contains \(cache.count) items")
        
        // Test cache manager
        CacheManager.shared.printCacheStatus()
        
        print("🎉 Basic cache test completed!\n")
    }
    
    /// Test repository caching with mock data
    static func testRepositoryCaching() {
        print("🏪 Testing Repository Cache Integration")
        print("=====================================")
        
        let cacheManager = CacheManager.shared
        
        // Test gym cache
        let testGym = createSampleGym()
        cacheManager.gymCache.set(testGym, forKey: CacheManager.CacheKeys.gymById(testGym.id))
        
        if let cachedGym = cacheManager.gymCache.get(forKey: CacheManager.CacheKeys.gymById(testGym.id)) {
            print("✅ Gym cached and retrieved: \(cachedGym.name)")
        }
        
        // Test user cache
        let testUser = createSampleUser()
        cacheManager.userCache.set(testUser, forKey: CacheManager.CacheKeys.userById(testUser.id))
        
        if let cachedUser = cacheManager.userCache.get(forKey: CacheManager.CacheKeys.userById(testUser.id)) {
            print("✅ User cached and retrieved: \(cachedUser.firstName) \(cachedUser.lastName)")
        }
        
        // Print final status
        cacheManager.printCacheStatus()
        
        print("🎉 Repository cache test completed!\n")
    }
    
    // MARK: - Sample Data Helpers
    
    private static func createSampleGym() -> Gym {
        return Gym(
            id: "test-gym-\(UUID().uuidString.prefix(8))",
            email: "test@gym.com",
            name: "Test Climbing Gym",
            description: "A sample gym for cache testing",
            location: LocationData(latitude: 51.5074, longitude: -0.1278, address: "London, UK"),
            climbingType: [.bouldering, .sport],
            amenities: [.cafe, .wifi],
            events: [],
            profileImage: nil,
            createdAt: Date()
        )
    }
    
    private static func createSampleUser() -> User {
        return User(
            id: "test-user-\(UUID().uuidString.prefix(8))",
            email: "test@user.com",
            firstName: "Test",
            lastName: "User",
            createdAt: Date(),
            favoriteGyms: [],
            favoriteEvents: []
        )
    }
}

// MARK: - ViewModels Extension for Testing

extension HomeViewModel {
    
    /// Test cache functionality from a ViewModel context
    func testCacheIntegration() {
        #if DEBUG
        print("🏠 Testing HomeViewModel Cache Integration")
        print("=========================================")
        
        Task {
            // This will use the cached repositories
            await fetchEvents()
            await fetchUserAndFavorites()
            
            print("✅ HomeViewModel cache integration tested")
            RepositoryFactory.printCacheStatus()
        }
        #endif
    }
}
#endif
