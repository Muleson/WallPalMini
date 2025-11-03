//
//  RepositoryFactory.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import Foundation
import Combine
import PhotosUI

// MARK: - Repository Factory
struct RepositoryFactory {
    
    static func debugCompilationConditions() {
        print("🔍 RepositoryFactory.debugCompilationConditions() called")
        #if USE_LOCAL_DATA
        print("✅ USE_LOCAL_DATA is ACTIVE")
        #else
        print("❌ USE_LOCAL_DATA is NOT ACTIVE")
        #endif
    }
    
    #if USE_LOCAL_DATA
    static func createGymRepository() -> GymRepositoryProtocol {
        print("🔄 Using LOCAL data repositories")
        return LocalGymRepository()
    }
    
    static func createEventRepository() -> EventRepositoryProtocol {
        return LocalEventRepository()
    }
    
    static func createUserRepository() -> UserRepositoryProtocol {
        return LocalUserRepository()
    }
    
    static func createMediaRepository() -> MediaRepositoryProtocol {
        return LocalMediaRepository()
    }
    
    static func createPermissionRepository() -> PermissionRepositoryProtocol {
        return LocalGymPermissionRepository()
    }

    static func createGymCompanyRepository() -> GymCompanyRepositoryProtocol {
        return LocalGymCompanyRepository()
    }

    #else
    static func createGymRepository() -> GymRepositoryProtocol {
        print("☁️ Using FIREBASE data repositories with CACHE")
        let baseRepository = FirebaseGymRepository()
        return CachedGymRepository(baseRepository: baseRepository)
    }
    
    static func createEventRepository() -> EventRepositoryProtocol {
        print("☁️ Using FIREBASE data repositories with CACHE")
        let baseRepository = FirebaseEventRepository()
        return CachedEventRepository(baseRepository: baseRepository)
    }
    
    static func createUserRepository() -> UserRepositoryProtocol {
        print("☁️ Using FIREBASE data repositories with CACHE")
        let baseRepository = FirebaseUserRepository()
        return CachedUserRepository(baseRepository: baseRepository)
    }
    
    static func createMediaRepository() -> MediaRepositoryProtocol {
        return FirebaseMediaRepository() // Assuming you have this
    }
    
    static func createPermissionRepository() -> PermissionRepositoryProtocol {
        return FirebaseGymPermissionRepository()
    }

    static func createGymCompanyRepository() -> GymCompanyRepositoryProtocol {
        return FirebaseGymCompanyRepository()
    }
    #endif
}

// MARK: - Cache Management Extensions

extension RepositoryFactory {
    
    /// Create uncached repositories for admin operations or when fresh data is required
    static func createUncachedGymRepository() -> GymRepositoryProtocol {
        #if USE_LOCAL_DATA
        return LocalGymRepository()
        #else
        return FirebaseGymRepository()
        #endif
    }
    
    static func createUncachedEventRepository() -> EventRepositoryProtocol {
        #if USE_LOCAL_DATA
        return LocalEventRepository()
        #else
        return FirebaseEventRepository()
        #endif
    }
    
    static func createUncachedUserRepository() -> UserRepositoryProtocol {
        #if USE_LOCAL_DATA
        return LocalUserRepository()
        #else
        return FirebaseUserRepository()
        #endif
    }
    
    /// Clear all repository caches
    static func clearAllCaches() {
        CacheManager.shared.clearAllCaches()
    }
    
    #if DEBUG
    /// Print cache status for debugging
    static func printCacheStatus() {
        CacheManager.shared.printCacheStatus()
    }
    #endif
}
