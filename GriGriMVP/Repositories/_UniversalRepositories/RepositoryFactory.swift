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
    
    static func createGymPermissionRepository() -> PermissionRepositoryProtocol {
        return LocalGymPermissionRepository()
    }
        
    #else
    static func createGymRepository() -> GymRepositoryProtocol {
        print("☁️ Using FIREBASE data repositories")
        return FirebaseGymRepository()
    }
    
    static func createEventRepository() -> EventRepositoryProtocol {
        return FirebaseEventRepository()
    }
    
    static func createUserRepository() -> UserRepositoryProtocol {
        return FirebaseUserRepository()
    }
    
    static func createMediaRepository() -> MediaRepositoryProtocol {
        return FirebaseMediaRepository() // Assuming you have this
    }
    
    static func createGymPermissionRepository() -> PermissionRepositoryProtocol {
        return FirebaseGymPermissionRepository()
    }
    #endif
}
