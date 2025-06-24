//
//  EventItem.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

struct EventItem: Identifiable, Equatable {
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
    
    init(
        id: String,
        author: User,
        host: Gym,
        name: String,
        type: EventType,
        location: String,
        description: String,
        mediaItems: [MediaItem]? = nil,
        registrationLink: String? = nil,
        createdAt: Date = Date(),
        eventDate: Date,
        isFeatured: Bool = false,
        registrationRequired: Bool = false
    ) {
        self.id = id
        self.author = author
        self.host = host
        self.name = name
        self.type = type
        self.location = location
        self.description = description
        self.mediaItems = mediaItems
        self.registrationLink = registrationLink
        self.createdAt = createdAt
        self.eventDate = eventDate
        self.isFeatured = isFeatured
        self.registrationRequired = registrationRequired
    }
}

enum EventType: String, Codable, CaseIterable {
    case competition = "competition"
    case social = "social"
    case openDay = "openDay"
    case settingTaster = "settingTaster"
    case opening = "opening"
    
    var displayName: String {
        switch self {
        case .competition:
            return "Competition"
        case .social:
            return "Social Event"
        case .openDay:
            return "Open Day"
        case .settingTaster:
            return "Setting Taster"
        case .opening:
            return "Grand Opening"
        }
    }
}
