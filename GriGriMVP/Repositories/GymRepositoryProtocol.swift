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
} 
