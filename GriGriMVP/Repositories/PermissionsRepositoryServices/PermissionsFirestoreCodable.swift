//
//  PermissionsFirestoreCodable.swift
//  GriGriMVP
//
//  Created by Sam Quested on 22/08/2025.
//

import Foundation
import FirebaseFirestore

extension GymPermission: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "gymId": gymId,
            "role": role.rawValue,
            "grantedAt": grantedAt.firestoreTimestamp,
            "grantedBy": grantedBy,
            "isValid": isValid
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        if let expiresAt = expiresAt {
            data["expiresAt"] = expiresAt.firestoreTimestamp
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard let id = firestoreData["id"] as? String,
              let userId = firestoreData["userId"] as? String,
              let gymId = firestoreData["gymId"] as? String,
              let roleString = firestoreData["role"] as? String,
              let role = GymRole(rawValue: roleString),
              let grantedBy = firestoreData["grantedBy"] as? String else {
            return nil
        }
        
        let grantedAt: Date
        if let timestamp = firestoreData["grantedAt"] as? Timestamp {
            grantedAt = timestamp.dateValue()
        } else {
            grantedAt = Date()
        }
        
        let notes = firestoreData["notes"] as? String
        
        let expiresAt: Date?
        if let expiresTimestamp = firestoreData["expiresAt"] as? Timestamp {
            expiresAt = expiresTimestamp.dateValue()
        } else {
            expiresAt = nil
        }
        
        self.init(
            id: id,
            userId: userId,
            gymId: gymId,
            role: role,
            grantedAt: grantedAt,
            grantedBy: grantedBy,
            notes: notes,
            expiresAt: expiresAt
        )
    }
}

// MARK: - Error Types
enum GymPermissionError: LocalizedError {
    case insufficientPermissions
    case notAuthenticated
    case permissionExpired
    case gymNotFound
    case userNotFound
    case notOwner
    case permissionAlreadyExists(userId: String, gymId: String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .notAuthenticated:
            return "You must be logged in"
        case .permissionExpired:
            return "Your permission has expired"
        case .gymNotFound:
            return "Gym not found"
        case .userNotFound:
            return "User not found"
        case .notOwner:
            return "Only the gym owner can perform this action"
        case .permissionAlreadyExists(let userId, let gymId):
            return "User \(userId) already has permissions for gym \(gymId)"
        }
    }
}
