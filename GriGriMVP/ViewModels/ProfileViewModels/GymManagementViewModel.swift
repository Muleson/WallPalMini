//
//  GymManagementViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import Foundation

@MainActor
class GymManagementViewModel: ObservableObject {
    @Published var gyms: [Gym] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(gymRepository: GymRepositoryProtocol = FirebaseGymRepository(),
         userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
        self.gymRepository = gymRepository
        self.userRepository = userRepository
    }
    
    func loadGyms() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user ID
            guard let currentUserId = userRepository.getCurrentAuthUser() else {
                print("DEBUG: No current user ID found")
                errorMessage = "You must be logged in to manage gyms"
                isLoading = false
                return
            }
            
            print("DEBUG: Loading gyms for user ID: \(currentUserId)")
            
            // Load only gyms that the current user can manage (owner or staff)
            let managedGyms = try await gymRepository.getGymsUserCanManage(userId: currentUserId)
            print("DEBUG: Repository returned \(managedGyms.count) gyms")
            
            gyms = managedGyms.sorted { $0.createdAt > $1.createdAt } // Most recent first
            print("DEBUG: View model now has \(gyms.count) gyms")
            
        } catch {
            print("DEBUG: Error loading gyms: \(error)")
            errorMessage = "Failed to load gyms: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteGym(_ gym: Gym) async {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            errorMessage = "You must be logged in to delete gyms"
            return
        }
        
        do {
            // Only owners can delete gyms
            guard gym.isOwner(userId: currentUserId) else {
                errorMessage = "Only the gym owner can delete this gym"
                return
            }
            
            // Delete the gym
            try await gymRepository.deleteGym(id: gym.id)
            
            // Remove from local array
            gyms.removeAll { $0.id == gym.id }
            
        } catch {
            errorMessage = "Failed to delete gym: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Permission Helpers
    
    func canUserDeleteGym(_ gym: Gym) -> Bool {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return false
        }
        
        // Only owners can delete gyms
        return gym.isOwner(userId: currentUserId)
    }
    
    func canUserManageStaff(_ gym: Gym) -> Bool {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return false
        }
        
        // Only owners can manage staff
        return gym.canAddStaff(userId: currentUserId)
    }
    
    func canUserCreateEvents(_ gym: Gym) -> Bool {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return false
        }
        
        // Both owners and staff can create events
        return gym.canCreateEvents(userId: currentUserId)
    }
    
    func getUserRoleForGym(_ gym: Gym) -> String {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return "Unknown"
        }
        
        if gym.isOwner(userId: currentUserId) {
            return "Owner"
        } else if gym.isStaff(userId: currentUserId) {
            return "Staff"
        } else {
            return "Member"
        }
    }
    
    // MARK: - Gym Statistics
    
    func getStaffCount(for gym: Gym) -> Int {
        return gym.staffUserIds.count
    }
    
    func getEventCount(for gym: Gym) -> Int {
        return gym.events.count
    }
    
    func getGymSummary(for gym: Gym) -> String {
        let staffCount = getStaffCount(for: gym)
        let eventCount = getEventCount(for: gym)
        
        var components: [String] = []
        
        if staffCount > 0 {
            components.append("\(staffCount) staff")
        }
        
        if eventCount > 0 {
            components.append("\(eventCount) events")
        }
        
        return components.isEmpty ? "No activity" : components.joined(separator: " • ")
    }
    
    // MARK: - Search and Filtering
    
    func filterGyms(by searchText: String) -> [Gym] {
        guard !searchText.isEmpty else { return gyms }
        
        let lowercaseSearch = searchText.lowercased()
        
        return gyms.filter { gym in
            gym.name.lowercased().contains(lowercaseSearch) ||
            gym.email.lowercased().contains(lowercaseSearch) ||
            gym.location.address?.lowercased().contains(lowercaseSearch) == true ||
            gym.description?.lowercased().contains(lowercaseSearch) == true
        }
    }
    
    func getOwnedGyms() -> [Gym] {
        guard let currentUserId = userRepository.getCurrentAuthUser() else { return [] }
        
        return gyms.filter { gym in
            gym.isOwner(userId: currentUserId)
        }
    }
    
    func getStaffGyms() -> [Gym] {
        guard let currentUserId = userRepository.getCurrentAuthUser() else { return [] }
        
        return gyms.filter { gym in
            gym.isStaff(userId: currentUserId) && !gym.isOwner(userId: currentUserId)
        }
    }
    
    // MARK: - Data Refresh
    
    func refreshGym(_ gym: Gym) async {
        do {
            if let updatedGym = try await gymRepository.getGym(id: gym.id) {
                // Update the gym in our local array
                if let index = gyms.firstIndex(where: { $0.id == gym.id }) {
                    gyms[index] = updatedGym
                }
            }
        } catch {
            errorMessage = "Failed to refresh gym data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Bulk Operations
    
    func refreshAllGyms() async {
        await loadGyms()
    }
}
