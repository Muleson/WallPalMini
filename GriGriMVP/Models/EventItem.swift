//
//  EventItem.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

struct EventItem: Identifiable, Equatable, Hashable {
    var id: String
    var author: User
    var host: Gym
    var name: String
    var eventType: EventType
    var climbingType: [ClimbingTypes]?
    var location: String
    var description: String
    var mediaItems: [MediaItem]?
    var registrationLink: String?
    var createdAt: Date
    var startDate: Date
    var endDate: Date
    var isFeatured: Bool
    var registrationRequired: Bool
    var frequency: EventFrequency?
    var recurrenceEndDate: Date?
    
    init(
        id: String,
        author: User,
        host: Gym,
        name: String,
        eventType: EventType,
        climbingType: [ClimbingTypes]? = nil,
        location: String,
        description: String,
        mediaItems: [MediaItem]? = nil,
        registrationLink: String? = nil,
        createdAt: Date = Date(),
        startDate: Date,
        endDate: Date,
        isFeatured: Bool = false,
        registrationRequired: Bool = false,
        frequency: EventFrequency? = nil,
        recurrenceEndDate: Date? = nil
    ) {
        self.id = id
        self.author = author
        self.host = host
        self.name = name
        self.eventType = eventType
        self.climbingType = climbingType
        self.location = location
        self.description = description
        self.mediaItems = mediaItems
        self.registrationLink = registrationLink
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.isFeatured = isFeatured
        self.registrationRequired = registrationRequired
        self.frequency = frequency
        self.recurrenceEndDate = recurrenceEndDate
    }
}

enum EventType: String, Codable, CaseIterable {
    case competition = "competition"
    case social = "social"
    case openDay = "openDay"
    case settingTaster = "settingTaster"
    case opening = "opening"
    case gymClass = "class"
    
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
        case .gymClass:
            return "Class"
        }
    }
}

enum EventFrequency: String, Codable, CaseIterable {
    case oneTime = "oneTime"
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .oneTime:
            return "One-off Event"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Every 2 Weeks"
        case .monthly:
            return "Monthly"
        }
    }
}
