//
//  Gym.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import FirebaseFirestore

struct Gym: Identifiable, Equatable, Codable {
    var id: String
    let email: String
    let name: String
    let description: String?
    let location: LocationData
    let climbingType: [ClimbingTypes]
    let amenities: [String]
    let events: [String]
    let imageUrl: URL?
    let createdAt: Date
    
    // Simplified staff management
    let ownerId: String
    let staffUserIds: [String]
    
    init(id: String, email: String, name: String, description: String?, location: LocationData, climbingType: [ClimbingTypes], amenities: [String], events: [String], imageUrl: URL?, createdAt: Date, ownerId: String, staffUserIds: [String] = []) {
        self.id = id
        self.email = email
        self.name = name
        self.description = description
        self.location = location
        self.climbingType = climbingType
        self.amenities = amenities
        self.events = events
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.ownerId = ownerId
        self.staffUserIds = staffUserIds
    }
    
    // Simple permission checks
    func isOwner(userId: String) -> Bool {
        return ownerId == userId
    }
    
    func isStaff(userId: String) -> Bool {
        return staffUserIds.contains(userId)
    }
    
    func canManageGym(userId: String) -> Bool {
        return isOwner(userId: userId) || isStaff(userId: userId)
    }
    
    func canAddStaff(userId: String) -> Bool {
        return isOwner(userId: userId) // Only owner can add/remove staff
    }
    
    func canCreateEvents(userId: String) -> Bool {
        return canManageGym(userId: userId) // Both owner and staff can create events
    }
    
    // Helper methods for staff management
    func addingStaff(_ userId: String) -> Gym {
        guard !staffUserIds.contains(userId) && userId != ownerId else { return self }
        
        var newStaffIds = staffUserIds
        newStaffIds.append(userId)
        
        return Gym(
            id: id, email: email, name: name, description: description,
            location: location, climbingType: climbingType, amenities: amenities,
            events: events, imageUrl: imageUrl, createdAt: createdAt,
            ownerId: ownerId, staffUserIds: newStaffIds
        )
    }
    
    func removingStaff(_ userId: String) -> Gym {
        let newStaffIds = staffUserIds.filter { $0 != userId }
        
        return Gym(
            id: id, email: email, name: name, description: description,
            location: location, climbingType: climbingType, amenities: amenities,
            events: events, imageUrl: imageUrl, createdAt: createdAt,
            ownerId: ownerId, staffUserIds: newStaffIds
        )
    }
}

struct GymAdministrator: Identifiable, Codable {
    let id: String
    let userId: String
    let gymId: String
    let role: AdminRole
    let addedAt: Date
    let addedBy: String
    
    enum AdminRole: String, Codable {
        case owner
        case admin
        case manager
    }
}

enum ClimbingTypes: String, Codable, CaseIterable {
    case bouldering
    case lead
    case topRope
}


struct GymFavorite: Identifiable, Codable, Equatable {
    let userId: String
    let gymId: String
    
    var id: String {
        return "\(userId)-\(gymId)"
    }
}

struct LocationData: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
    let address: String?
}

// Simple staff info for display purposes
struct StaffMember: Identifiable {
    let id: String
    let name: String
    let email: String
    let addedAt: Date
    
    init(user: User, addedAt: Date = Date()) {
        self.id = user.id
        self.name = "\(user.firstName) \(user.lastName)"
        self.email = user.email
        self.addedAt = addedAt
    }
}

// Placeholder for event codable
extension Gym {
    /// Creates a minimal placeholder Gym with just an ID for use in relationships
    static func placeholder(id: String) -> Gym {
        return Gym(
            id: id,
            email: "",
            name: "Loading...",
            description: nil,
            location: LocationData(latitude: 0, longitude: 0, address: nil),
            climbingType: [],
            amenities: [],
            events: [],
            imageUrl: nil,
            createdAt: Date(),
            ownerId: "",
            staffUserIds: []
        )
    }
}
