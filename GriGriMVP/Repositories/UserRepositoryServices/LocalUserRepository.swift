//
//  LocalUserRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import Foundation

class LocalUserRepository: UserRepositoryProtocol {
    private var users = SampleData.users
    private var currentUserId: String? = "user1" // Default to first user for testing
    
    // Authentication methods
    func signIn(email: String, password: String) async throws -> User {
        // Find user by email for local testing
        if let user = users.first(where: { $0.email == email }) {
            currentUserId = user.id
            return user
        }
        throw NSError(domain: "LocalAuth", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
    }
    
    func createUser(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        let newUser = User(
            id: UUID().uuidString,
            email: email,
            firstName: firstName,
            lastName: lastName,
            createdAt: Date(),
            favoriteGyms: nil,
            favoriteEvents: nil
        )
        users.append(newUser)
        currentUserId = newUser.id
        return newUser
    }
    
    func signOut() throws {
        currentUserId = nil
    }
    
    func getCurrentAuthUser() -> String? {
        return currentUserId
    }
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
            // For local testing, we'll simulate the Apple Sign In flow
            // In a real app, this would never be called for LocalUserRepository
            
            // Extract name components or use defaults
            let firstName = fullName?.givenName ?? "Apple"
            let lastName = fullName?.familyName ?? "User"
            
            // Generate a unique Apple-style user ID for local testing
            let appleUserId = "apple_user_" + UUID().uuidString.prefix(8)
            
            // Check if this "Apple user" already exists (simulate returning user)
            if let existingUser = users.first(where: { $0.email.contains("appleid.com") && $0.firstName == firstName && $0.lastName == lastName }) {
                currentUserId = existingUser.id
                return existingUser
            }
            
            // Create new Apple user for local testing
            let newAppleUser = User(
                id: appleUserId,
                email: "apple.user.\(UUID().uuidString.prefix(6))@privaterelay.appleid.com",
                firstName: firstName,
                lastName: lastName,
                createdAt: Date(),
                favoriteGyms: [],
                favoriteEvents: []
            )
            
            // Add to local users array
            users.append(newAppleUser)
            currentUserId = newAppleUser.id
            
            // Simulate network delay for realistic testing
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            return newAppleUser
        }

    
    // User data methods
    func getUser(id: String) async throws -> User? {
        return users.first { $0.id == id }
    }
    
    func getCurrentUser() async throws -> User? {
        guard let userId = currentUserId else { return nil }
        return users.first { $0.id == userId }
    }
    
    func updateUser(_ user: User) async throws {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
    }
    
    // Favorite management methods
    func updateUserFavoriteGyms(userId: String, gymId: String, isFavorite: Bool) async throws -> [String] {
        guard let index = users.firstIndex(where: { $0.id == userId }) else {
            throw NSError(domain: "LocalUser", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        let currentUser = users[index]
        var favoriteGyms = currentUser.favoriteGyms ?? []
        
        if isFavorite {
            if !favoriteGyms.contains(gymId) {
                favoriteGyms.append(gymId)
            }
        } else {
            favoriteGyms.removeAll { $0 == gymId }
        }
        
        let updatedUser = User(
            id: currentUser.id,
            email: currentUser.email,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName,
            createdAt: currentUser.createdAt,
            favoriteGyms: favoriteGyms,
            favoriteEvents: currentUser.favoriteEvents
        )
        users[index] = updatedUser
        
        return favoriteGyms
    }
    
    func updateUserFavoriteEvents(userId: String, eventId: String, isFavorite: Bool) async throws -> [String] {
        guard let index = users.firstIndex(where: { $0.id == userId }) else {
            throw NSError(domain: "LocalUser", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        let currentUser = users[index]
        var favoriteEvents = currentUser.favoriteEvents ?? []
        
        if isFavorite {
            if !favoriteEvents.contains(eventId) {
                favoriteEvents.append(eventId)
            }
        } else {
            favoriteEvents.removeAll { $0 == eventId }
        }
        
        let updatedUser = User(
            id: currentUser.id,
            email: currentUser.email,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName,
            createdAt: currentUser.createdAt,
            favoriteGyms: currentUser.favoriteGyms,
            favoriteEvents: favoriteEvents
        )
        users[index] = updatedUser
        
        return favoriteEvents
    }
}
