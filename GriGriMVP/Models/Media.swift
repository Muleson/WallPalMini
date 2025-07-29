//
//  Media.swift
//  GriGriMVP
//
//  Created by Sam Quested on 13/05/2025.
//

import Foundation
import FirebaseFirestore

struct MediaItem: Identifiable, Equatable, Hashable {
    let id: String
    let url: URL
    let type: MediaType
    let uploadedAt: Date
    let ownerId: String
    
    // MARK: - Standard Initializer
    init(id: String, url: URL, type: MediaType, uploadedAt: Date, ownerId: String) {
        self.id = id
        self.url = url
        self.type = type
        self.uploadedAt = uploadedAt
        self.ownerId = ownerId
    }
}

enum MediaType: String, Codable {
    case image
    case none
}
