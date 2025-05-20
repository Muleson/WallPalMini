//
//  Media.swift
//  GriGriMVP
//
//  Created by Sam Quested on 13/05/2025.
//

import Foundation

struct MediaItem: Identifiable, Codable, Equatable {
    let id: String
    let url: URL
    let type: MediaType
    let uploadedAt: Date
    let ownerId: String
}

enum MediaType: String, Codable {
    case image
    case none
}
