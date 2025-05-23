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
    
    init(gymRepository: GymRepositoryProtocol = FirebaseGymRepository()) {
        self.gymRepository = gymRepository
    }
    
    func loadGyms() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedGyms = try await gymRepository.fetchAllGyms()
            gyms = loadedGyms
        } catch {
            errorMessage = "Failed to load gyms: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteGym(_ gym: Gym) async {
        // In a real implementation, you'd call the repository to delete the gym
        // For now, we'll just remove it from the local array
        gyms.removeAll { $0.id == gym.id }
    }
}
