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
    
    init(mediaRepository: MediaRepositoryProtocol = FirebaseMediaRepository()) {
        self.mediaRepository = mediaRepository
    }
    
    // MARK: - Fetch Methods
    
    func fetchAllGyms() async throws -> [Gym] {
        let snapshot = try await db.collection(gymsCollection).getDocuments()
        return snapshot.documents.compactMap { document -> Gym? in
            var data = document.data()
            data["id"] = document.documentID  // Add document ID to data
            
            let gym = Gym(firestoreData: data)
            if gym == nil {
                print("Error decoding gym with ID: \(document.documentID)")
            }
            return gym
        }
    }
    
    func searchGyms(query: String) async throws -> [Gym] {
        // If query is empty, return all gyms
        if query.isEmpty {
            return try await fetchAllGyms()
        }
        
        // Create a query that searches by name
        let lowercaseQuery = query.lowercased()
        
        // Using multiple queries for more comprehensive search
        let nameQuery = db.collection(gymsCollection)
            .whereField("name", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        let locationQuery = db.collection(gymsCollection)
            .whereField("location.address", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("location.address", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        // Execute both queries
        async let nameSnapshot = nameQuery.getDocuments()
        async let locationSnapshot = locationQuery.getDocuments()
        
        // Combine results
        let (nameResults, locationResults) = try await (nameSnapshot, locationSnapshot)
        var uniqueGyms = [String: Gym]()
        
        // Process name results
        for document in nameResults.documents {
            var data = document.data()
            data["id"] = document.documentID
            
            if let gym = Gym(firestoreData: data) {
                uniqueGyms[document.documentID] = gym
            } else {
                print("Error decoding gym from name search with ID: \(document.documentID)")
            }
        }
        
        // Process location results
        for document in locationResults.documents {
            // Only add if not already in results
            if uniqueGyms[document.documentID] == nil {
                var data = document.data()
                data["id"] = document.documentID
                
                if let gym = Gym(firestoreData: data) {
                    uniqueGyms[document.documentID] = gym
                } else {
                    print("Error decoding gym from location search with ID: \(document.documentID)")
                }
            }
        }
        
        return Array(uniqueGyms.values)
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
    
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws {
        // Update the user document with the new favorite gyms
        try await db.collection("users").document(userId).updateData([
            "favouriteGyms": favoritedGymIds
        ])
    }
    
    // MARK: - Create Methods
    
    func createGym(_ gym: Gym) async throws -> Gym {
        // Convert gym to Firestore data using FirestoreCodable
        let gymData = gym.toFirestoreData()
        
        // Add to Firestore
        let documentRef = try await db.collection(gymsCollection).addDocument(data: gymData)
        
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
    
    // MARK: - Update Methods
     
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
    
    // MARK: - Delete Methods
     
    func deleteGym(id: String) async throws {
        // Get gym to check for image
        if let gym = try await getGym(id: id),
           let profileImage = gym.profileImage {
            // Delete associated image
            try? await mediaRepository.deleteMedia(profileImage)
        }
        
        // Delete gym document
        try await db.collection(gymsCollection).document(id).delete()
    }
    
    // MARK: - Staff Management Methods
    
    func addStaffMember(to gymId: String, userId: String) async throws {
        let gymRef = db.collection(gymsCollection).document(gymId)
        
        try await gymRef.updateData([
            "staffUserIds": FieldValue.arrayUnion([userId])
        ])
    }
    
    func removeStaffMember(from gymId: String, userId: String) async throws {
        let gymRef = db.collection(gymsCollection).document(gymId)
        
        try await gymRef.updateData([
            "staffUserIds": FieldValue.arrayRemove([userId])
        ])
    }
    
    func getStaffMembers(for gymId: String) async throws -> [StaffMember] {
        guard let gym = try await getGym(id: gymId) else {
            throw NSError(domain: "GymRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Gym not found"
            ])
        }
        
        var staffMembers: [StaffMember] = []
        
        // Get user details for each staff member
        for staffUserId in gym.staffUserIds {
            if let user = try await getUserById(staffUserId) {
                let staffMember = StaffMember(user: user)
                staffMembers.append(staffMember)
            }
        }
        
        return staffMembers
    }
    
    // MARK: - User Search for Staff Addition
    
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
    
    // MARK: - Gym Access Check
    
    func getGymsUserCanManage(userId: String) async throws -> [Gym] {
        // Query for gyms where user is owner
        let ownerQuery = db.collection(gymsCollection)
            .whereField("ownerId", isEqualTo: userId)
        
        // Query for gyms where user is staff
        let staffQuery = db.collection(gymsCollection)
            .whereField("staffUserIds", arrayContains: userId)
        
        // Execute both queries concurrently
        async let ownerSnapshot = ownerQuery.getDocuments()
        async let staffSnapshot = staffQuery.getDocuments()
        
        let (ownerResults, staffResults) = try await (ownerSnapshot, staffSnapshot)

        var uniqueGyms = [String: Gym]()
        
        // Process owned gyms
        for document in ownerResults.documents {
            var data = document.data()
            data["id"] = document.documentID  // Add document ID to data
            
            if let gym = Gym(firestoreData: data) {
                uniqueGyms[document.documentID] = gym
            }
        }
        
        // Process staff gyms
        for document in staffResults.documents {
            if uniqueGyms[document.documentID] == nil {
                var data = document.data()
                data["id"] = document.documentID  // Add document ID to data
                
                if let gym = Gym(firestoreData: data) {
                    uniqueGyms[document.documentID] = gym
                }
            }
        }
        
        return Array(uniqueGyms.values)
    }
    
    // MARK: - Helper Methods
    
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
        
        // Add all required fields for a Gym object
        let requiredFields = ["name", "email", "location", "ownerId"]
        
        for field in requiredFields {
            if data[field] == nil {
                missingFields.append(field)
            }
        }
        
        return missingFields
    }
}
