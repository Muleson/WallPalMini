//
//  Gym.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import FirebaseFirestore

struct Gym: Identifiable, Equatable, Hashable {
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
    
    // Verification status for gym approval process
    var verificationStatus: GymVerificationStatus
    var verificationNotes: String?
    var verifiedAt: Date?
    var verifiedBy: String?
    
    
    init(id: String, email: String, name: String, description: String?, location: LocationData, climbingType: [ClimbingTypes], amenities: [Amenities], events: [String], profileImage: MediaItem?, createdAt: Date, verificationStatus: GymVerificationStatus = .pending, verificationNotes: String? = nil, verifiedAt: Date? = nil, verifiedBy: String? = nil) {
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
        self.verificationStatus = verificationStatus
        self.verificationNotes = verificationNotes
        self.verifiedAt = verifiedAt
        self.verifiedBy = verifiedBy
    }
    
    // Verification status checks
    var isLive: Bool {
        return verificationStatus == .approved
    }
    
    var isPendingVerification: Bool {
        return verificationStatus == .pending
    }
    
    var isRejected: Bool {
        return verificationStatus == .rejected
    }
    
    
    // Verification status management
    func updatingVerificationStatus(_ status: GymVerificationStatus, notes: String? = nil, verifiedBy: String? = nil) -> Gym {
        return Gym(
            id: id, email: email, name: name, description: description,
            location: location, climbingType: climbingType, amenities: amenities,
            events: events, profileImage: profileImage, createdAt: createdAt,
            verificationStatus: status,
            verificationNotes: notes, verifiedAt: status != .pending ? Date() : nil, verifiedBy: verifiedBy
        )
    }
}

// MARK: - Verification Status Enum
enum GymVerificationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Verification"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        }
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

enum ClimbingTypes: String, Codable, CaseIterable, Hashable {
    case bouldering
    case sport
    case board
    case gym
}

enum Amenities: String, Codable, CaseIterable, Hashable {
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
        )
    }
}
