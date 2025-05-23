//
//  GymRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/05/2025.
//

import Foundation
import Combine

protocol GymRepositoryProtocol {
    /// Fetch all gyms
    func fetchAllGyms() async throws -> [Gym]
    
    /// Search for gyms by name or location
    func searchGyms(query: String) async throws -> [Gym]
    
    /// Get a specific gym by ID
    func getGym(id: String) async throws -> Gym?
    
    /// Update user's favorite gyms
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws
    
    /// Create a new gym
     func createGym(_ gym: Gym) async throws -> Gym
     
     /// Update an existing gym
     func updateGym(_ gym: Gym) async throws -> Gym
     
     /// Delete a gym
     func deleteGym(id: String) async throws
}
