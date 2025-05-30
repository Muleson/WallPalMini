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
        return try snapshot.documents.compactMap { document -> Gym? in
            do {
                var gym = try document.data(as: Gym.self)
                gym.id = document.documentID
                return gym
            } catch {
                print("Error decoding gym: \(error)")
                return nil
            }
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
            .whereField("location", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("location", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
        
        // Execute both queries
        async let nameSnapshot = nameQuery.getDocuments()
        async let locationSnapshot = locationQuery.getDocuments()
        
        // Combine results
        let (nameResults, locationResults) = try await (nameSnapshot, locationSnapshot)
        var uniqueGyms = [String: Gym]()
        
        // Process name results
        for document in nameResults.documents {
            do {
                var gym = try document.data(as: Gym.self)
                gym.id = document.documentID
                uniqueGyms[document.documentID] = gym
            } catch {
                print("Error decoding gym from name search: \(error)")
            }
        }
        
        // Process location results
        for document in locationResults.documents {
            // Only add if not already in results
            if uniqueGyms[document.documentID] == nil {
                do {
                    var gym = try document.data(as: Gym.self)
                    gym.id = document.documentID
                    uniqueGyms[document.documentID] = gym
                } catch {
                    print("Error decoding gym from location search: \(error)")
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
            
            // Add more detailed logging
            let missingFields = checkRequiredGymFields(data)
            if !missingFields.isEmpty {
                print("DEBUG: Gym document \(id) is missing fields: \(missingFields.joined(separator: ", "))")
            }
            
            // Add the ID to the data
            var gymData = data
            gymData["id"] = document.documentID
            
            // Use a more robust initializer
            return Gym(firestoreData: gymData)
        } catch {
            print("DEBUG: Error in getGym(\(id)): \(error.localizedDescription)")
            // Try to create a minimal placeholder instead of throwing
            return Gym.placeholder(id: id)
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
        var gymToCreate = gym
        
        // Convert gym to Firestore data
        let gymData = gymToCreate.toFirestoreData()
        
        // Add to Firestore
        let documentRef = try await db.collection(gymsCollection).addDocument(data: gymData)
        
        // Update the gym with the generated ID
        gymToCreate.id = documentRef.documentID
        
        return gymToCreate
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
        
        // Update gym with new MediaItem
        try await db.collection(gymsCollection).document(gymId).updateData([
            "image": [
                "id": mediaItem.id,
                "url": mediaItem.url.absoluteString,
                "type": mediaItem.type.rawValue,
                "uploadedAt": mediaItem.uploadedAt.firestoreTimestamp,
                "ownerId": mediaItem.ownerId
            ]
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
            if let user = User(firestoreData: document.data()) {
                var userWithId = user
                // Assuming User has mutable id or init with id
                users.append(userWithId)
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
            if var firestoreData = document.data() as? [String: Any] {
                // Create a gym using the FirestoreCodable initializer
                if let gym = Gym(firestoreData: firestoreData) {
                    var gymWithId = gym
                    gymWithId.id = document.documentID // Set the ID from the document ID
                    uniqueGyms[document.documentID] = gymWithId
                }
            }
        }
        
        // Process staff gyms
        for document in staffResults.documents {
            if uniqueGyms[document.documentID] == nil {
                if var firestoreData = document.data() as? [String: Any] {
                    if let gym = Gym(firestoreData: firestoreData) {
                        var gymWithId = gym
                        gymWithId.id = document.documentID
                        uniqueGyms[document.documentID] = gymWithId
                    }
                }
            }
        }
        
        return Array(uniqueGyms.values)
    }
    
    // MARK: - Helper Methods
    
    private func getUserById(_ userId: String) async throws -> User? {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        guard userDoc.exists else { return nil }
        
        return User(firestoreData: userDoc.data() ?? [:])
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
