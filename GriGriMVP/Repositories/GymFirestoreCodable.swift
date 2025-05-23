//
//  GymFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/05/2025.
//

import Foundation
import FirebaseFirestore

class FirebaseGymRepository: GymRepositoryProtocol {
    private let db = Firestore.firestore()
    private let gymsCollection = "gyms"
    
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
        let documentSnapshot = try await db.collection(gymsCollection).document(id).getDocument()
        
        if documentSnapshot.exists {
            var gym = try documentSnapshot.data(as: Gym.self)
            gym.id = documentSnapshot.documentID
            return gym
        }
        
        return nil
    }
    
    func updateUserFavoriteGyms(userId: String, favoritedGymIds: [String]) async throws {
        // Update the user document with the new favorite gyms
        try await db.collection("users").document(userId).updateData([
            "favouriteGyms": favoritedGymIds
        ])
    }
}
