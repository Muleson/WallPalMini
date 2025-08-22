//
//  LocalGymRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import Foundation
import PhotosUI

class LocalGymRepository: GymRepositoryProtocol {
    private var gyms = SampleData.gyms
    private let permissionRepository: PermissionRepositoryProtocol // NEW dependency
    
    init(permissionRepository: PermissionRepositoryProtocol? = nil) {
        self.permissionRepository = permissionRepository ?? LocalGymPermissionRepository()
    }
    
    func fetchAllGyms() async throws -> [Gym] {
        return gyms
    }
    
    func searchGyms(query: String) async throws -> [Gym] {
        return gyms.filter { gym in
            gym.name.localizedCaseInsensitiveContains(query) ||
            gym.description?.localizedCaseInsensitiveContains(query) == true ||
            gym.location.address?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    func getGym(id: String) async throws -> Gym? {
        return gyms.first { $0.id == id }
    }
    
    // NEW: Get multiple gyms by IDs
    func getGyms(ids: [String]) async throws -> [Gym] {
        return gyms.filter { ids.contains($0.id) }
    }
    
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws {
        print("Updated user \(userId) favorite gyms to: \(favoritedGymIds)")
    }
    
    // UPDATED: Now creates permission
    func createGym(_ gym: Gym, ownerId: String) async throws -> Gym {
        gyms.append(gym)
        
        // Create owner permission
        let ownerPermission = GymPermission(
            userId: ownerId,
            gymId: gym.id,
            role: .owner,
            grantedBy: ownerId,
            notes: "Gym creator"
        )
        
        try await permissionRepository.grantPermission(ownerPermission)
        
        return gym
    }
    
    func updateGym(_ gym: Gym) async throws -> Gym {
        if let index = gyms.firstIndex(where: { $0.id == gym.id }) {
            gyms[index] = gym
        }
        return gym
    }
    
    func updateGymImage(gymId: String, image: UIImage) async throws -> URL {
        // Return sample URL for local testing
        return URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4")!
    }
    
    // UPDATED: Now deletes permissions
    func deleteGym(id: String) async throws {
        // Delete all permissions for this gym
        let permissions = try await permissionRepository.getPermissionsForGym(gymId: id)
        for permission in permissions {
            try await permissionRepository.revokePermission(permissionId: permission.id)
        }
        
        gyms.removeAll { $0.id == id }
    }
        
    // Kept for user search
    func searchUsers(query: String) async throws -> [User] {
        return SampleData.users.filter {
            $0.firstName.localizedCaseInsensitiveContains(query) ||
            $0.lastName.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
    
    func updateGymVerificationStatus(gymId: String, status: GymVerificationStatus, notes: String?, verifiedBy: String?) async throws -> Gym {
        guard let index = gyms.firstIndex(where: { $0.id == gymId }) else {
            throw NSError(domain: "GymRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Gym not found"
            ])
        }
        
        let updatedGym = gyms[index].updatingVerificationStatus(status, notes: notes, verifiedBy: verifiedBy)
        gyms[index] = updatedGym
        
        return updatedGym
    }
    
    func getGymsByVerificationStatus(_ status: GymVerificationStatus) async throws -> [Gym] {
        return gyms.filter { $0.verificationStatus == status }
    }
}
