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
    let favouriteGyms: [Gym.ID]?
}
