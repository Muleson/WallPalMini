//
//  User.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

struct User: Identifiable, Equatable, Hashable {
    var id: String
    var email: String
    var firstName: String
    var lastName: String
    var createdAt: Date
    var favoriteGyms: [String]?  // Changed from [Gym.ID] to [String] for clarity
    var favoriteEvents: [String]?  // Changed from [EventItem.ID] to [String] for clarity
    
    // MARK: - Initializers
    init(
        id: String,
        email: String,
        firstName: String,
        lastName: String,
        createdAt: Date = Date(),
        favoriteGyms: [String]? = nil,
        favoriteEvents: [String]? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.favoriteGyms = favoriteGyms
        self.favoriteEvents = favoriteEvents
    }
}

struct UserFavorite: Identifiable {
    let id: String
    let userId: String
    let eventId: String
    let dateAdded: Date
    
    init(id: String, userId: String, eventId: String, dateAdded: Date = Date()) {
        self.id = id
        self.userId = userId
        self.eventId = eventId
        self.dateAdded = dateAdded
    }
}

// MARK: - Placeholder Extension
extension User {
    /// Creates a minimal placeholder User with just an ID for use in relationships
    static func placeholder(id: String) -> User {
        return User(
            id: id,
            email: "",
            firstName: "Loading...",
            lastName: "",
            createdAt: Date(),
            favoriteGyms: nil,
            favoriteEvents: nil
        )
    }
}
