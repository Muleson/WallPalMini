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
     
     func updateGym(_ gym: Gym) async throws -> Gym {
         let gymData = gym.toFirestoreData()
         
         try await db.collection(gymsCollection).document(gym.id).setData(gymData, merge: true)
         
         return gym
     }
     
     func deleteGym(id: String) async throws {
         try await db.collection(gymsCollection).document(id).delete()
     }
}
