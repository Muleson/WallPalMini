//
//  FirebaseUserRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/05/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseUserRepository: UserRepositoryProtocol {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let usersCollection = "users"
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        
        guard let user = try await getUser(id: authResult.user.uid) else {
            throw NSError(domain: "FirebaseUserRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "User data not found after authentication"
            ])
        }
        
        return user
    }
    
    func createUser(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        let authResult = try await auth.createUser(withEmail: email, password: password)
        
        let user = User(
            id: authResult.user.uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            createdAt: Date(),
            favoriteGyms: [],
            favoriteEvents: []
            
        )
        
        try await db.collection(usersCollection).document(user.id).setData(user.toFirestoreData())
        
        return user
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func getCurrentAuthUser() -> String? {
        return auth.currentUser?.uid
    }
    
    // MARK: - User Data
    
    func getUser(id: String) async throws -> User? {
        let documentSnapshot = try await db.collection(usersCollection).document(id).getDocument()
        
        guard documentSnapshot.exists else {
            return nil
        }
        
        // Add the document ID to the data before decoding
        var userData = documentSnapshot.data() ?? [:]
        userData["id"] = documentSnapshot.documentID
        
        let user = User(firestoreData: userData)
        
        if user == nil {
            print("DEBUG: Failed to decode user with ID: \(id)")
            print("DEBUG: Document data keys: \(userData.keys.sorted())")
        }
        
        return user
    }
    
    func getCurrentUser() async throws -> User? {
        guard let userId = getCurrentAuthUser() else {
            return nil
        }
        
        return try await getUser(id: userId)
    }
    
    func updateUser(_ user: User) async throws {
        try await db.collection(usersCollection).document(user.id).setData(user.toFirestoreData())
    }
    
    // MARK: - Favorite Gyms Management
    
    func updateUserFavoriteGyms(userId: String, gymId: String, isFavorite: Bool) async throws -> [String] {
        // Get the current user document
        let documentSnapshot = try await db.collection(usersCollection).document(userId).getDocument()
        
        // Get current favorite gyms array
        var favoriteGyms = documentSnapshot.data()?["favouriteGyms"] as? [String] ?? []
        
        if isFavorite {
            // Add gym to favorites if not already there
            if !favoriteGyms.contains(gymId) {
                favoriteGyms.append(gymId)
            }
        } else {
            // Remove gym from favorites
            favoriteGyms.removeAll { $0 == gymId }
        }
        
        // Update the user document with new favorites
        try await db.collection(usersCollection).document(userId).updateData([
            "favouriteGyms": favoriteGyms
        ])
        
        return favoriteGyms
    }
    
    // MARK: - Favorite Events Management
    
    func updateUserFavoriteEvents(userId: String, eventId: String, isFavorite: Bool) async throws -> [String] {
        // Get the current user document
        let documentSnapshot = try await db.collection(usersCollection).document(userId).getDocument()
        
        // Get current favorite events array
        var favoriteEvents = documentSnapshot.data()?["favouriteEvents"] as? [String] ?? []
        
        if isFavorite {
            // Add event to favorites if not already there
            if !favoriteEvents.contains(eventId) {
                favoriteEvents.append(eventId)
            }
        } else {
            // Remove event from favorites
            favoriteEvents.removeAll { $0 == eventId }
        }
        
        // Update the user document with new favorites
        try await db.collection(usersCollection).document(userId).updateData([
            "favouriteEvents": favoriteEvents
        ])
        
        return favoriteEvents
    }
}
