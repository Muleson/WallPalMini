//
//  GymPermissions.swift
//  GriGriMVP
//
//  Created by Sam Quested on 22/08/2025.
//

import Foundation
import FirebaseFirestore

struct GymPermission: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let gymId: String
    let role: GymRole
    let grantedAt: Date
    let grantedBy: String  // User ID who granted this permission
    
    // Optional metadata
    let notes: String?
    let expiresAt: Date?  // For temporary permissions if needed
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        gymId: String,
        role: GymRole,
        grantedAt: Date = Date(),
        grantedBy: String,
        notes: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.gymId = gymId
        self.role = role
        self.grantedAt = grantedAt
        self.grantedBy = grantedBy
        self.notes = notes
        self.expiresAt = expiresAt
    }
    
    // Check if permission is still valid
    var isValid: Bool {
        guard let expiresAt = expiresAt else { return true }
        return Date() < expiresAt
    }
}

// MARK: - GymRole Enum
enum GymRole: String, Codable, CaseIterable {
    case owner = "owner"
    case staff = "staff"
    case eventManager = "event_manager"  // Future: Can only manage events
    case viewer = "viewer"  // Future: Read-only access
    
    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .staff:
            return "Staff"
        case .eventManager:
            return "Event Manager"
        case .viewer:
            return "Viewer"
        }
    }
    
    // Permission capabilities
    var canEditGymDetails: Bool {
        switch self {
        case .owner:
            return true
        case .staff, .eventManager, .viewer:
            return false
        }
    }
    
    var canManageStaff: Bool {
        return self == .owner
    }
    
    var canCreateEvents: Bool {
        switch self {
        case .owner, .staff, .eventManager:
            return true
        case .viewer:
            return false
        }
    }
    
    var canDeleteGym: Bool {
        return self == .owner
    }
}
