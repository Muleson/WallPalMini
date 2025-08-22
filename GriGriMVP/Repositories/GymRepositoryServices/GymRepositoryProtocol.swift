//
//  GymRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/05/2025.
//

import Foundation
import UIKit

protocol GymRepositoryProtocol {
    /// Fetch all gyms
    func fetchAllGyms() async throws -> [Gym]
    
    /// Search for gyms by name or location
    func searchGyms(query: String) async throws -> [Gym]
    
    /// Get a specific gym by ID
    func getGym(id: String) async throws -> Gym?
    
    /// Get multiple gyms by IDs (NEW - for permission-based fetching)
    func getGyms(ids: [String]) async throws -> [Gym]
    
    /// Update user's favorite gyms
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws
    
    /// Create a new gym (UPDATED - now takes ownerId parameter)
    func createGym(_ gym: Gym, ownerId: String) async throws -> Gym

    /// Update an existing gym
    func updateGym(_ gym: Gym) async throws -> Gym
    
    /// Update gym profile image
    func updateGymImage(gymId: String, image: UIImage) async throws -> URL
     
    /// Delete a gym
    func deleteGym(id: String) async throws
    
    /// Search for users by query (kept for user search functionality)
    func searchUsers(query: String) async throws -> [User]
    
    /// Update gym verification status
    func updateGymVerificationStatus(gymId: String, status: GymVerificationStatus, notes: String?, verifiedBy: String?) async throws -> Gym
    
    /// Get gyms by verification status
    func getGymsByVerificationStatus(_ status: GymVerificationStatus) async throws -> [Gym]
}
