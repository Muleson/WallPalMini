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
    
    init(id: String, email: String, name: String, description: String?, location: LocationData, climbingType: [ClimbingTypes], amenities: [String], events: [String], imageUrl: URL?, createdAt: Date) {
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
