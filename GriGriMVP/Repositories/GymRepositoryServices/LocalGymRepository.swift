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
    
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws {
        print("Updated user \(userId) favorite gyms to: \(favoritedGymIds)")
    }
    
    func createGym(_ gym: Gym) async throws -> Gym {
        gyms.append(gym)
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
    
    func deleteGym(id: String) async throws {
        gyms.removeAll { $0.id == id }
    }
    
    func getStaffMembers(for gymId: String) async throws -> [StaffMember] {
        return SampleData.getStaffMembers(for: gymId)
    }
    
    func removeStaffMember(from gymId: String, userId: String) async throws {
        if let index = gyms.firstIndex(where: { $0.id == gymId }) {
            gyms[index] = gyms[index].removingStaff(userId)
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        return SampleData.users.filter {
            $0.firstName.localizedCaseInsensitiveContains(query) ||
            $0.lastName.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
    
    func addStaffMember(to gymId: String, userId: String) async throws {
        if let index = gyms.firstIndex(where: { $0.id == gymId }) {
            gyms[index] = gyms[index].addingStaff(userId)
        }
    }
    
    func getGymsUserCanManage(userId: String) async throws -> [Gym] {
        return SampleData.getGymsForUser(userId: userId)
    }
}
