//
//  StaffViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//


import Foundation

@MainActor
class StaffViewModel: ObservableObject {
    @Published var staffMembers: [StaffMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let gym: Gym
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    var currentUserId: String? {
        return userRepository.getCurrentAuthUser()
    }
    
    init(gym: Gym, 
         gymRepository: GymRepositoryProtocol = FirebaseGymRepository(),
         userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
        self.gym = gym
        self.gymRepository = gymRepository
        self.userRepository = userRepository
    }
    
    func loadStaff() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let staff = try await gymRepository.getStaffMembers(for: gym.id)
            staffMembers = staff
        } catch {
            errorMessage = "Failed to load staff: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func removeStaff(_ userId: String) async {
        do {
            try await gymRepository.removeStaffMember(from: gym.id, userId: userId)
            staffMembers.removeAll { $0.id == userId }
        } catch {
            errorMessage = "Failed to remove staff member: \(error.localizedDescription)"
        }
    }
}

@MainActor
class AddStaffViewModel: ObservableObject {
    @Published var searchResults: [User] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let gymRepository: GymRepositoryProtocol
    
    init(gymRepository: GymRepositoryProtocol = FirebaseGymRepository()) {
        self.gymRepository = gymRepository
    }
    
    func searchUsers(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let users = try await gymRepository.searchUsers(query: trimmedQuery)
            searchResults = users
        } catch {
            errorMessage = "Failed to search users: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    func addStaffMember(to gymId: String, userId: String) async {
        do {
            try await gymRepository.addStaffMember(to: gymId, userId: userId)
        } catch {
            errorMessage = "Failed to add staff member: \(error.localizedDescription)"
        }
    }
}
