//
//  EventItem.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

struct EventItem: Identifiable, Equatable, Codable {
    var id: String
    var author: User
    var host: Gym
    var name: String
    var type: EventType
    var location: String
    var description: String
    var mediaItems: [MediaItem]?
    var registrationLink: String?
    var createdAt: Date
    var eventDate: Date
    var isFeatured: Bool
    var registrationRequired: Bool
}

enum EventType: String, Codable {
    case competition
    case social
    case openDay
    case settingTaster
    case opening
}
