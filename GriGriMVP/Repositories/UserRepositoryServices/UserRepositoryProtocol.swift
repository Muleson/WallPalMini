//
//  UserRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation

protocol UserRepositoryProtocol {
    // Authentication
    func signIn(email: String, password: String) async throws -> User
    func createUser(email: String, password: String, firstName: String, lastName: String) async throws -> User
    func signOut() throws
    func getCurrentAuthUser() -> String?
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User
    
    // User data
    func getUser(id: String) async throws -> User?
    func getCurrentUser() async throws -> User?
    func updateUser(_ user: User) async throws
    
    // Favorite gyms management
    func updateUserFavoriteGyms(userId: String, gymId: String, isFavorite: Bool) async throws -> [String]
    
    // Favorite events management
    func updateUserFavoriteEvents(userId: String, eventId: String, isFavorite: Bool) async throws -> [String]
}

