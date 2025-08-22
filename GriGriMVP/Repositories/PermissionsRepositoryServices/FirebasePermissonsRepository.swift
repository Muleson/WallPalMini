//
//  FirebasePermissonsRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 22/08/2025.
//

import Foundation
import FirebaseFirestore

class FirebaseGymPermissionRepository: PermissionRepositoryProtocol {
    private let db = Firestore.firestore()
    private let permissionsCollection = "gymPermissions"
    private let usersCollection = "users"
    
    // MARK: - Fetch Methods
    
    func getPermissionsForUser(userId: String) async throws -> [GymPermission] {
        let snapshot = try await db.collection(permissionsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isValid", isEqualTo: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> GymPermission? in
            var data = document.data()
            data["id"] = document.documentID
            return GymPermission(firestoreData: data)
        }
    }
    
    func getPermissionsForGym(gymId: String) async throws -> [GymPermission] {
        let snapshot = try await db.collection(permissionsCollection)
            .whereField("gymId", isEqualTo: gymId)
            .whereField("isValid", isEqualTo: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> GymPermission? in
            var data = document.data()
            data["id"] = document.documentID
            return GymPermission(firestoreData: data)
        }
    }
    
    func getPermission(userId: String, gymId: String) async throws -> GymPermission? {
        let snapshot = try await db.collection(permissionsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("gymId", isEqualTo: gymId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        
        var data = document.data()
        data["id"] = document.documentID
        return GymPermission(firestoreData: data)
    }
    
    // MARK: - Create/Update Methods
    
    func grantPermission(_ permission: GymPermission) async throws {
        // Check if permission already exists
        if let existing = try await getPermission(userId: permission.userId, gymId: permission.gymId) {
            throw GymPermissionError.permissionAlreadyExists(userId: permission.userId, gymId: permission.gymId)
        }
        
        let data = permission.toFirestoreData()
        let ref = db.collection(permissionsCollection).document(permission.id)
        try await ref.setData(data)
    }
    
    func updatePermission(_ permission: GymPermission) async throws {
        let data = permission.toFirestoreData()
        try await db.collection(permissionsCollection)
            .document(permission.id)
            .setData(data, merge: true)
    }
    
    func revokePermission(permissionId: String) async throws {
        try await db.collection(permissionsCollection)
            .document(permissionId)
            .delete()
    }
    
    // MARK: - Ownership Transfer
    
    func transferOwnership(gymId: String, fromUserId: String, toUserId: String) async throws {
        let batch = db.batch()
        
        // Get current owner permission
        guard let ownerPermission = try await getPermission(userId: fromUserId, gymId: gymId),
              ownerPermission.role == .owner else {
            throw GymPermissionError.notOwner
        }
        
        // Check new owner doesn't already have permission
        if let existingPermission = try await getPermission(userId: toUserId, gymId: gymId) {
            // Update existing permission to owner
            let updatedPermission = GymPermission(
                id: existingPermission.id,
                userId: toUserId,
                gymId: gymId,
                role: .owner,
                grantedAt: existingPermission.grantedAt,
                grantedBy: fromUserId,
                notes: "Ownership transferred from \(fromUserId)"
            )
            batch.setData(updatedPermission.toFirestoreData(),
                         forDocument: db.collection(permissionsCollection).document(existingPermission.id))
        } else {
            // Create new owner permission
            let newOwnerPermission = GymPermission(
                userId: toUserId,
                gymId: gymId,
                role: .owner,
                grantedBy: fromUserId,
                notes: "Ownership transferred"
            )
            batch.setData(newOwnerPermission.toFirestoreData(),
                         forDocument: db.collection(permissionsCollection).document(newOwnerPermission.id))
        }
        
        // Downgrade previous owner to staff
        let downgradedPermission = GymPermission(
            id: ownerPermission.id,
            userId: fromUserId,
            gymId: gymId,
            role: .staff,
            grantedAt: ownerPermission.grantedAt,
            grantedBy: ownerPermission.grantedBy,
            notes: "Previous owner - transferred to \(toUserId)"
        )
        batch.setData(downgradedPermission.toFirestoreData(),
                     forDocument: db.collection(permissionsCollection).document(ownerPermission.id))
        
        try await batch.commit()
    }
    
    // MARK: - Batch Operations
    
    func getPermissionsForGyms(gymIds: [String], userId: String) async throws -> [GymPermission] {
        guard !gymIds.isEmpty else { return [] }
        
        // Firestore 'in' queries are limited to 10 items
        var allPermissions: [GymPermission] = []
        
        for chunk in gymIds.chunked(into: 10) {
            let snapshot = try await db.collection(permissionsCollection)
                .whereField("userId", isEqualTo: userId)
                .whereField("gymId", in: chunk)
                .getDocuments()
            
            let permissions = snapshot.documents.compactMap { document -> GymPermission? in
                var data = document.data()
                data["id"] = document.documentID
                return GymPermission(firestoreData: data)
            }
            
            allPermissions.append(contentsOf: permissions)
        }
        
        return allPermissions
    }
    
    func getUsersWithPermissions(for gymId: String) async throws -> [(user: User, permission: GymPermission)] {
        let permissions = try await getPermissionsForGym(gymId: gymId)
        var results: [(User, GymPermission)] = []
        
        for permission in permissions {
            if let user = try await getUserById(permission.userId) {
                results.append((user, permission))
            }
        }
        
        return results
    }
    
    func hasPermission(userId: String, gymId: String) async throws -> Bool {
        let permission = try await getPermission(userId: userId, gymId: gymId)
        return permission != nil && (permission?.isValid ?? false)
    }
    
    func getGymsForUserWithRole(userId: String, role: GymRole) async throws -> [String] {
        let snapshot = try await db.collection(permissionsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("role", isEqualTo: role.rawValue)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> String? in
            let data = document.data()
            return data["gymId"] as? String
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserById(_ userId: String) async throws -> User? {
        let userDoc = try await db.collection(usersCollection).document(userId).getDocument()
        
        guard userDoc.exists, let data = userDoc.data() else { return nil }
        
        var userData = data
        userData["id"] = userDoc.documentID
        
        return User(firestoreData: userData)
    }
}
