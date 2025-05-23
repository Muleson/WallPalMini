//
//  User.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

struct User: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: Date
    let favoriteGyms: [Gym.ID]?
    let favoriteEvents: [EventItem.ID]? 
}

struct UserFavorite: Identifiable {
    let id: String
    let userId: String
    let eventId: String
    let dateAdded: Date
}

// Placeholder for event codable
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
