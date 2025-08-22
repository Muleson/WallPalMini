//
//  FirebaseGymRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import Foundation
import FirebaseFirestore

class FirebaseGymRepository: GymRepositoryProtocol {    
    private let db = Firestore.firestore()
    private let gymsCollection = "gyms"
    private let usersCollection = "users"
    private let mediaRepository: MediaRepositoryProtocol
    private let permissionRepository: PermissionRepositoryProtocol
    
    init(mediaRepository: MediaRepositoryProtocol = RepositoryFactory.createMediaRepository(),
         permissionRepository: PermissionRepositoryProtocol? = nil) {
        self.mediaRepository = mediaRepository
        // Use injected permission repository or create default
        self.permissionRepository = permissionRepository ?? FirebaseGymPermissionRepository()
    }
    
    // MARK: - Fetch Methods (mostly unchanged)
    
    func fetchAllGyms() async throws -> [Gym] {
        let snapshot = try await db.collection(gymsCollection).getDocuments()
        return snapshot.documents.compactMap { document -> Gym? in
            var data = document.data()
            data["id"] = document.documentID
            return Gym(firestoreData: data)
        }
    }
    
    func searchGyms(query: String) async throws -> [Gym] {
        let lowercaseQuery = query.lowercased()
        
        let nameQuery = db.collection(gymsCollection)
            .whereField("name", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 20)
        
        let snapshot = try await nameQuery.getDocuments()
        
        return snapshot.documents.compactMap { document -> Gym? in
            var data = document.data()
            data["id"] = document.documentID
            return Gym(firestoreData: data)
        }
    }
    
    func getGym(id: String) async throws -> Gym? {
        do {
            let document = try await db.collection(gymsCollection).document(id).getDocument()
            
            guard let data = document.data() else {
                return nil // Document doesn't exist
            }
            
            // Add the ID to the data before decoding
            var gymData = data
            gymData["id"] = document.documentID
            
            // Use FirestoreCodable initializer
            let gym = Gym(firestoreData: gymData)
            
            if gym == nil {
                print("DEBUG: Failed to decode gym with ID: \(id)")
                print("DEBUG: Document data keys: \(gymData.keys.sorted())")
                let missingFields = checkRequiredGymFields(gymData)
                if !missingFields.isEmpty {
                    print("DEBUG: Missing required fields: \(missingFields.joined(separator: ", "))")
                }
            }
            
            return gym
        } catch {
            print("DEBUG: Error in getGym(\(id)): \(error.localizedDescription)")
            throw error
        }
    }
    
    // NEW: Get multiple gyms by IDs
    func getGyms(ids: [String]) async throws -> [Gym] {
        guard !ids.isEmpty else { return [] }
        
        var allGyms: [Gym] = []
        
        // Firestore 'in' queries are limited to 10 items
        for chunk in ids.chunked(into: 10) {
            let snapshot = try await db.collection(gymsCollection)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            let gyms = snapshot.documents.compactMap { document -> Gym? in
                var data = document.data()
                data["id"] = document.documentID
                return Gym(firestoreData: data)
            }
            
            allGyms.append(contentsOf: gyms)
        }
        
        return allGyms
    }
    
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws {
        // Update the user document with the new favorite gyms
        try await db.collection("users").document(userId).updateData([
            "favouriteGyms": favoritedGymIds
        ])
    }
    
    // MARK: - Create Methods (UPDATED)
    
    func createGym(_ gym: Gym, ownerId: String) async throws -> Gym {
        // Convert gym to Firestore data using FirestoreCodable
        let gymData = gym.toFirestoreData()
        
        // Add to Firestore
        let documentRef = try await db.collection(gymsCollection).addDocument(data: gymData)
        
        // Create owner permission in the permissions collection
        let ownerPermission = GymPermission(
            userId: ownerId,
            gymId: documentRef.documentID,
            role: .owner,
            grantedBy: ownerId,
            notes: "Gym creator"
        )
        
        try await permissionRepository.grantPermission(ownerPermission)
        
        // Create updated gym with the generated ID
        var updatedGymData = gymData
        updatedGymData["id"] = documentRef.documentID
        
        guard let updatedGym = Gym(firestoreData: updatedGymData) else {
            throw NSError(domain: "GymRepository", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create gym with generated ID"
            ])
        }
        
        return updatedGym
    }
    
    // MARK: - Update Methods (mostly unchanged)
     
    func updateGym(_ gym: Gym) async throws -> Gym {
        let gymData = gym.toFirestoreData()
        
        try await db.collection(gymsCollection).document(gym.id).setData(gymData, merge: true)
        
        return gym
    }
    
    func updateGymImage(gymId: String, image: UIImage) async throws -> URL {
        guard let gym = try await getGym(id: gymId) else {
            throw NSError(domain: "GymRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Gym not found"
            ])
        }
        
        // Delete old image if exists
        if let oldImage = gym.profileImage {
            try? await mediaRepository.deleteMedia(oldImage)
        }
        
        // Upload new image
        let mediaItem = try await mediaRepository.uploadImage(
            image,
            ownerId: "gym_\(gymId)",
            compressionQuality: 0.8
        )
        
        // Update gym with new MediaItem using FirestoreCodable
        try await db.collection(gymsCollection).document(gymId).updateData([
            "profileImage": mediaItem.toFirestoreData()
        ])
        
        return mediaItem.url
    }
    
    func deleteGymImage(gymId: String) async throws {
        guard let gym = try await getGym(id: gymId) else {
            throw NSError(domain: "GymRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Gym not found"
            ])
        }
        
        guard let profileImage = gym.profileImage else {
            return // No image to delete
        }
        
        try await mediaRepository.deleteMedia(profileImage)
        
        // Update gym to remove image
        try await db.collection(gymsCollection).document(gymId).updateData([
            "profileImage": FieldValue.delete()
        ])
    }
    
    // MARK: - Delete Methods (UPDATED)
     
    func deleteGym(id: String) async throws {
        // NEW: Delete all permissions for this gym
        let permissions = try await permissionRepository.getPermissionsForGym(gymId: id)
        for permission in permissions {
            try await permissionRepository.revokePermission(permissionId: permission.id)
        }
        
        // Get gym to check for image
        if let gym = try await getGym(id: id),
           let profileImage = gym.profileImage {
            // Delete associated image
            try? await mediaRepository.deleteMedia(profileImage)
        }
        
        // Delete gym document
        try await db.collection(gymsCollection).document(id).delete()
    }
    
    // MARK: - User Search (kept for user search functionality)
    
    func searchUsers(query: String) async throws -> [User] {
        let lowercaseQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !lowercaseQuery.isEmpty else { return [] }
        
        // Search by email (most common use case)
        let emailQuery = db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("email", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 10)
        
        let snapshot = try await emailQuery.getDocuments()
        
        var users: [User] = []
        for document in snapshot.documents {
            var userData = document.data()
            userData["id"] = document.documentID
            
            if let user = User(firestoreData: userData) {
                users.append(user)
            }
        }
        
        return users
    }
    
    // MARK: - Verification Methods (unchanged)
    
    func updateGymVerificationStatus(gymId: String, status: GymVerificationStatus, notes: String?, verifiedBy: String?) async throws -> Gym {
        guard let gym = try await getGym(id: gymId) else {
            throw NSError(domain: "GymRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Gym not found"
            ])
        }
        
        let updatedGym = gym.updatingVerificationStatus(status, notes: notes, verifiedBy: verifiedBy)
        
        // Update the gym in Firestore
        try await updateGym(updatedGym)
        
        return updatedGym
    }
    
    func getGymsByVerificationStatus(_ status: GymVerificationStatus) async throws -> [Gym] {
        let query = db.collection(gymsCollection)
            .whereField("verificationStatus", isEqualTo: status.rawValue)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document -> Gym? in
            var data = document.data()
            data["id"] = document.documentID
            
            let gym = Gym(firestoreData: data)
            if gym == nil {
                print("DEBUG: Failed to decode gym with ID: \(document.documentID)")
                print("DEBUG: Available data keys: \(data.keys.sorted())")
            }
            return gym
        }
    }
    
    // MARK: - Helper Methods (kept from original)
    
    private func getUserById(_ userId: String) async throws -> User? {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        guard userDoc.exists, let data = userDoc.data() else { return nil }
        
        var userData = data
        userData["id"] = userDoc.documentID
        
        return User(firestoreData: userData)
    }
    
    // Helper function to check for missing fields
    private func checkRequiredGymFields(_ data: [String: Any]) -> [String] {
        var missingFields: [String] = []
        
        // Add all required fields for a Gym object (without ownerId and staffUserIds now)
        let requiredFields = ["name", "email", "location"]
        
        for field in requiredFields {
            if data[field] == nil {
                missingFields.append(field)
            }
        }
        
        return missingFields
    }
}
