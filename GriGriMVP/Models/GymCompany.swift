//
//  GymCompany.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/10/2025.
//

import Foundation

struct GymCompany: Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var description: String?
    var profileImage: MediaItem?
    var createdAt: Date
    
    // Associated gyms
    var gymIds: [String]?
    
    // Company operating info
    var email: String?
    var website: String?
}
