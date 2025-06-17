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
    var email: String
    var name: String
    var description: String?
    var location: LocationData
    var climbingType: [ClimbingTypes]
    var amenities: [Amenities]
    var events: [String]
    var profileImage: MediaItem?
    var createdAt: Date
    
    // staff management
    let ownerId: String
    let staffUserIds: [String]
    
    init(id: String, email: String, name: String, description: String?, location: LocationData, climbingType: [ClimbingTypes], amenities: [Amenities], events: [String], profileImage: MediaItem?, createdAt: Date, ownerId: String, staffUserIds: [String] = []) {
        self.id = id
        self.email = email
        self.name = name
        self.description = description
        self.location = location
        self.climbingType = climbingType
        self.amenities = amenities
        self.events = events
        self.profileImage = profileImage
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
            events: events, profileImage: profileImage, createdAt: createdAt,
            ownerId: ownerId, staffUserIds: newStaffIds
        )
    }
    
    func removingStaff(_ userId: String) -> Gym {
        let newStaffIds = staffUserIds.filter { $0 != userId }
        
        return Gym(
            id: id, email: email, name: name, description: description,
            location: location, climbingType: climbingType, amenities: amenities,
            events: events, profileImage: profileImage, createdAt: createdAt,
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
    case sport
    case board
    case gym
}

enum Amenities: String, Codable, CaseIterable {
    case showers = "Showers"
    case lockers = "Lockers"
    case bar = "Bar"
    case food = "Food"
    case changingRooms = "Changing Rooms"
    case bathrooms = "Bathrooms"
    case cafe = "Cafe"
    case bikeStorage = "Bike Storage"
    case workSpace = "Work Space"
    case shop = "Gear Shop"
    case wifi = "Wifi"
}


struct GymFavorite: Identifiable, Codable, Equatable {
    let userId: String
    let gymId: String
    
    var id: String {
        return "\(userId)-\(gymId)"
    }
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
            profileImage: nil,
            createdAt: Date(),
            ownerId: "",
            staffUserIds: []
        )
    }
}
