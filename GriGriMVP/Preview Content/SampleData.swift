//
//  SampleData.swift
//  GriGriMVP
//
//  Created by Sam Quested on 13/05/2025.
//

import Foundation
import UIKit

struct SampleData {
    
    // MARK: - Users
    static let users = [
        User(
            id: "user1",
            email: "john.doe@example.com",
            firstName: "John",
            lastName: "Doe",
            createdAt: Date(timeIntervalSince1970: 1620000000),
            favoriteGyms: ["gym1", "gym3"],
            favoriteEvents: ["event1", "event3"]
        ),
        User(
            id: "user2",
            email: "jane.smith@example.com",
            firstName: "Jane",
            lastName: "Smith",
            createdAt: Date(timeIntervalSince1970: 1625000000),
            favoriteGyms: ["gym2"],
            favoriteEvents: ["event2", "event4"]
        ),
        User(
            id: "user3",
            email: "alex.wilson@example.com",
            firstName: "Alex",
            lastName: "Wilson",
            createdAt: Date(timeIntervalSince1970: 1630000000),
            favoriteGyms: nil,
            favoriteEvents: nil
        ),
        User(
            id: "user4",
            email: "sarah.johnson@example.com",
            firstName: "Sarah",
            lastName: "Johnson",
            createdAt: Date(timeIntervalSince1970: 1635000000),
            favoriteGyms: ["gym1"],
            favoriteEvents: ["event1"]
        ),
        User(
            id: "user5",
            email: "mike.brown@example.com",
            firstName: "Mike",
            lastName: "Brown",
            createdAt: Date(timeIntervalSince1970: 1640000000),
            favoriteGyms: [],
            favoriteEvents: []
        )
    ]
    
    // MARK: - Media Items
    static let mediaItems = [
        MediaItem(
            id: "media1",
            url: URL(string: "local-asset://SampleLogo1")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1648000000),
            ownerId: "gym1"
        ),
        MediaItem(
            id: "media2",
            url: URL(string: "local-asset://SampleLogo2")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1649000000),
            ownerId: "gym2"
        ),
        MediaItem(
            id: "media3",
            url: URL(string: "local-asset://SampleLogo3")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1650000000),
            ownerId: "gym3"
        ),
        MediaItem(
            id: "media4",
            url: URL(string: "local-asset://SampleLogo4")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1650000000),
            ownerId: "gym4"
        ),
        MediaItem(
            id: "media5",
            url: URL(string: "local-asset://SamplePoster2-1")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1651000000),
            ownerId: "event1"
        ),
        MediaItem(
            id: "media6",
            url: URL(string: "local-asset://SamplePoster3-1")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1652000000),
            ownerId: "event2"
        ),
        MediaItem(
            id: "media7",
            url: URL(string: "local-asset://SamplePoster4-1")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1651000000),
            ownerId: "event3"
        ),
        MediaItem(
            id: "media8",
            url: URL(string: "local-asset://SamplePoster4-2")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1652000000),
            ownerId: "event4"
        ),
        MediaItem(
            id: "media9",
            url: URL(string: "local-asset://SamplePoster4-3")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1653000000),
            ownerId: "event6"
        ),
        MediaItem(
            id: "media10",
            url: URL(string: "local-asset://SamplePosterX-1")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1653000000),
            ownerId: "event7"
        ),
        MediaItem(
            id: "media11",
            url: URL(string: "local-asset://SamplePosterX-2")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1653000000),
            ownerId: "event8"
        )
    ]
    
    // MARK: - Gyms with MediaItem Profile Images
    static let gyms = [
        Gym(
            id: "gym1",
            email: "info@rockvalley.com",
            name: "Rock Valley",
            description: "Premier bouldering facility with 200+ problems ranging from beginner to expert",
            location: LocationData(
                latitude: 51.5074,
                longitude: -0.1278,
                address: "123 Climb Street, London"
            ),
            climbingType: [.bouldering, .sport, .board, .gym],
            amenities: [.cafe, .changingRooms, .showers],
            events: [],
            profileImage: mediaItems[0], // Uses media1
            createdAt: Date(timeIntervalSince1970: 1610000000),
            ownerId: "user1", // John Doe is the owner
            staffUserIds: ["user2", "user4"] // Jane and Sarah are staff
        ),
        Gym(
            id: "gym2",
            email: "contact@vaultclimbing.com",
            name: "The Vault",
            description: "Indoor lead and top rope climbing center with routes for all abilities",
            location: LocationData(
                latitude: 51.4682,
                longitude: -0.1217,
                address: "456 Rock Avenue, Manchester"
            ),
            climbingType: [.sport, .gym],
            amenities: [.shop, .lockers, .showers],
            events: ["event2"],
            profileImage: mediaItems[1], // Uses media2
            createdAt: Date(timeIntervalSince1970: 1615000000),
            ownerId: "user2", // Jane Smith is the owner
            staffUserIds: ["user3", "user5"] // Alex and Mike are staff
        ),
        Gym(
            id: "gym3",
            email: "hello@gravity.com",
            name: "Gravity Climbing",
            description: "Family-friendly climbing center with bouldering and walls for all ages",
            location: LocationData(
                latitude: 51.5063,
                longitude: -0.2233,
                address: "789 Chalk Road, Bristol"
            ),
            climbingType: [.bouldering, .gym],
            amenities: [.changingRooms, .food, .bathrooms],
            events: [],
            profileImage: mediaItems[2], // Uses media3
            createdAt: Date(timeIntervalSince1970: 1620000000),
            ownerId: "user3", // Alex Wilson is the owner
            staffUserIds: [] // No staff yet
        ),
        Gym(
            id: "gym4",
            email: "hello@climbchurch.com",
            name: "The Church",
            description: "Iconic, state of the art climbing center in a beutifully unique former church",
            location: LocationData(
                latitude: 51.5038,
                longitude: -0.2666,
                address: "789 Chalk Road, Bristol"
            ),
            climbingType: [.bouldering, .gym],
            amenities: [.changingRooms, .food, .bathrooms],
            events: [],
            profileImage: mediaItems[3], // Uses media3
            createdAt: Date(timeIntervalSince1970: 1620000000),
            ownerId: "user3", // Alex Wilson is the owner
            staffUserIds: [] // No staff yet
        )

    ]
    
    // MARK: - Events with MediaItem Arrays
    static let events = [
        EventItem(
            id: "event1",
            author: users[0], // John Doe (owner of Boulder World)
            host: gyms[1], // The Vault Climbing
            name: "Community Climb",
            eventType: .openDay,
            climbingType: [.bouldering],
            location: "Boulder World, Main Hall",
            description: "Annual bouldering competition with categories for all levels. Cash prizes for top finishers!",
            mediaItems: [mediaItems[4]], // Multiple images for this event
            registrationLink: nil, //"https://example.com/register-summer-send"
            createdAt: Date(timeIntervalSince1970: 1650000000),
            startDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!.addingTimeInterval(8 * 3600), // 8 hours later
            isFeatured: true,
            registrationRequired: true
        ),
        EventItem(
            id: "event2",
            author: users[1], // Jane Smith (owner of Vertical Edge)
            host: gyms[1], // Vertical Edge
            name: "Zenith Bash",
            eventType: .openDay,
            climbingType: [.bouldering, .sport],
            location: "Training Area",
            description: "Learn the basics of climbing in this introductory session. Equipment provided.",
            mediaItems: [mediaItems[5]], // Multiple images for this event
            registrationLink: "https://example.com/register-workshop",
            createdAt: Date(timeIntervalSince1970: 1655000000),
            startDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
            endDate: Calendar.current.date(byAdding: .hour, value: 5, to: Date())!, // 2 hours later
            isFeatured: false,
            registrationRequired: false
        ),
        EventItem(
            id: "event3",
            author: users[3], // Sarah Johnson (staff at Boulder World)
            host: gyms[3], // The Church
            name: "Summer Send",
            eventType: .settingTaster,
            climbingType: [.bouldering],
            location: "The Steeple",
            description: "Come see our new routes and boulder problems set by guest setter Alex Megos!",
            mediaItems: [mediaItems[6]], // No images for this event
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1660000000),
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(4 * 3600), // 4 hours later
            isFeatured: true,
            registrationRequired: false
        ),
        EventItem(
            id: "event4",
            author: users[2], // Alex Wilson (owner of Crag Climb)
            host: gyms[3], // The Church
            name: "Rope Jam",
            eventType: .social,
            climbingType: [.sport],
            location: "Crag Climb",
            description: "Join us for the grand opening of our new facility! Free climbing all day and prizes.",
            mediaItems: [mediaItems[7]], // Single image for this event
            registrationLink: "https://example.com/grand-opening",
            createdAt: Date(timeIntervalSince1970: 1665000000),
            startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!.addingTimeInterval(12 * 3600), // All day event (12 hours)
            isFeatured: true,
            registrationRequired: true,
            frequency: .weekly
        ),
        EventItem(
            id: "event5",
            author: users[4], // Mike Brown (staff at Vertical Edge)
            host: gyms[3], // The Church
            name: "Elevate",
            eventType: .competition,
            climbingType: [.bouldering, .sport],
            location: "The Church",
            description: "Biggest competition where all our strongest climbers come together!",
            mediaItems: [mediaItems[8]],
            registrationLink: "https://example.com/youth-club",
            createdAt: Date(timeIntervalSince1970: 1670000000),
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!.addingTimeInterval(2 * 3600), // 2 hours later
            isFeatured: false,
            registrationRequired: true
        ),
        
     // Gym class samples
        EventItem(
            id: "event_class1",
            author: users[3], // Sarah Johnson (staff at Rock Valley)
            host: gyms[0], // Rock Valley
            name: "Beginner Bouldering Basics",
            eventType: .gymClass,
            climbingType: [.bouldering],
            location: "Rock Valley, Bouldering Area",
            description: "Perfect for those new to bouldering! Learn fundamental techniques, safety, and how to read routes. All equipment provided.",
            mediaItems: nil,
            registrationLink: "https://rockvalley.com/classes/beginner-bouldering",
            createdAt: Date(timeIntervalSince1970: 1672000000),
            startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!.addingTimeInterval(18 * 3600), // 6 PM, 2 days from now
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!.addingTimeInterval(19.5 * 3600), // 1.5 hour class
            isFeatured: false,
            registrationRequired: true,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) // 3 month course
        ),

        EventItem(
            id: "event_class2",
            author: users[1], // Jane Smith (owner of The Vault)
            host: gyms[1], // The Vault
            name: "Youth Climbing Club (Ages 8-16)",
            eventType: .gymClass,
            climbingType: [.sport, .bouldering],
            location: "The Vault, Youth Area",
            description: "Weekly climbing sessions for young climbers. Focuses on technique, strength building, and fun challenges. Parent supervision required for under 12s.",
            mediaItems: [mediaItems[5]], // Reusing existing media
            registrationLink: "https://thevault.com/youth-club",
            createdAt: Date(timeIntervalSince1970: 1675000000),
            startDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!.addingTimeInterval(16 * 3600), // 4 PM Saturday
            endDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!.addingTimeInterval(17.5 * 3600), // 1.5 hour class
            isFeatured: true,
            registrationRequired: true,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) // Ongoing program
        ),

        EventItem(
            id: "event_class3",
            author: users[4], // Mike Brown (staff at The Vault)
            host: gyms[1], // The Vault
            name: "Lead Climbing Progression",
            eventType: .gymClass,
            climbingType: [.sport],
            location: "The Vault, Sport Climbing Wall",
            description: "Take your lead climbing to the next level! Focus on advanced techniques, mental training, and efficient movement. Lead certification required.",
            mediaItems: nil,
            registrationLink: "https://thevault.com/lead-progression",
            createdAt: Date(timeIntervalSince1970: 1673000000),
            startDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!.addingTimeInterval(19 * 3600), // 7 PM Thursday
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!.addingTimeInterval(21 * 3600), // 2 hour class
            isFeatured: false,
            registrationRequired: true,
            frequency: .biweekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()) // 2 month intensive
        ),

        EventItem(
            id: "event_class4",
            author: users[2], // Alex Wilson (owner of Gravity Climbing)
            host: gyms[2], // Gravity Climbing
            name: "Family Climbing Adventures",
            eventType: .gymClass,
            climbingType: [.bouldering, .gym],
            location: "Gravity Climbing, Main Wall",
            description: "A fun climbing session designed for families! Parents and children climb together with structured activities and games. All skill levels welcome.",
            mediaItems: [mediaItems[6]], // Reusing existing media
            registrationLink: "https://gravity.com/family-climbing",
            createdAt: Date(timeIntervalSince1970: 1674000000),
            startDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!.addingTimeInterval(10 * 3600), // 10 AM next Sunday
            endDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!.addingTimeInterval(11.5 * 3600), // 1.5 hour class
            isFeatured: false,
            registrationRequired: true,
            frequency: .monthly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) // Ongoing monthly program
        ),

        EventItem(
            id: "event_class5",
            author: users[2], // Alex Wilson (owner of The Church)
            host: gyms[3], // The Church
            name: "Advanced Movement Workshop",
            eventType: .gymClass,
            climbingType: [.bouldering, .sport],
            location: "The Church, Main Hall",
            description: "Master complex climbing movements! This intensive workshop covers dynos, mantles, heel hooks, and body positioning. For experienced climbers only.",
            mediaItems: [mediaItems[7]], // Reusing existing media
            registrationLink: nil, // Drop-in class
            createdAt: Date(timeIntervalSince1970: 1676000000),
            startDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!.addingTimeInterval(14 * 3600), // 2 PM, 12 days from now
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!.addingTimeInterval(17 * 3600), // 3 hour intensive workshop
            isFeatured: true,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil // Single workshop
        ),

        EventItem(
            id: "event_class6",
            author: users[3], // Sarah Johnson (staff at Rock Valley)
            host: gyms[0], // Rock Valley
            name: "Women's Climbing Circle",
            eventType: .gymClass,
            climbingType: [.bouldering, .sport],
            location: "Rock Valley, Training Area",
            description: "A supportive environment for women to climb, learn, and connect. Monthly sessions focusing on technique, confidence building, and community.",
            mediaItems: nil,
            registrationLink: "https://rockvalley.com/womens-circle",
            createdAt: Date(timeIntervalSince1970: 1671000000),
            startDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!.addingTimeInterval(18.5 * 3600), // 6:30 PM
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!.addingTimeInterval(20.5 * 3600), // 2 hour session
            isFeatured: false,
            registrationRequired: true,
            frequency: .monthly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) // Ongoing program
        ),

        EventItem(
            id: "event_class7",
            author: users[4], // Mike Brown (now coaching at The Church)
            host: gyms[3], // The Church
            name: "Speed Climbing Bootcamp",
            eventType: .gymClass,
            climbingType: [.sport],
            location: "The Church, Speed Wall",
            description: "Train for speed climbing competitions! High-intensity sessions focusing on explosive power, precise footwork, and race tactics.",
            mediaItems: [mediaItems[8]], // Reusing existing media
            registrationLink: "https://thechurch.com/speed-training",
            createdAt: Date(timeIntervalSince1970: 1677000000),
            startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(20 * 3600), // 8 PM tomorrow
            endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(21.5 * 3600), // 1.5 hour intensive
            isFeatured: false,
            registrationRequired: true,
            frequency: .biweekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .month, value: 4, to: Date()) // 4 month training cycle
        ),

        EventItem(
            id: "event_class8",
            author: users[2], // Alex Wilson (owner of Gravity Climbing)
            host: gyms[2], // Gravity Climbing
            name: "Active Seniors Climbing",
            eventType: .gymClass,
            climbingType: [.gym],
            location: "Gravity Climbing, Low Wall Section",
            description: "Climbing sessions designed for active adults 55+. Focus on mobility, strength maintenance, and social connection in a relaxed environment.",
            mediaItems: nil,
            registrationLink: "https://gravity.com/seniors-climbing",
            createdAt: Date(timeIntervalSince1970: 1678000000),
            startDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!.addingTimeInterval(14 * 3600), // 2 PM, 15 days from now
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!.addingTimeInterval(15.5 * 3600), // 1.5 hour class
            isFeatured: false,
            registrationRequired: true,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) // Ongoing program
        )
      
    ]
    
    // MARK: - Helper Methods
    
    /// Get staff members for a specific gym
    static func getStaffMembers(for gymId: String) -> [StaffMember] {
        guard let gym = gyms.first(where: { $0.id == gymId }) else { return [] }
        
        return gym.staffUserIds.compactMap { staffId in
            guard let user = users.first(where: { $0.id == staffId }) else { return nil }
            return StaffMember(user: user)
        }
    }
    
    /// Check if user can manage a specific gym
    static func canUserManageGym(userId: String, gymId: String) -> Bool {
        guard let gym = gyms.first(where: { $0.id == gymId }) else { return false }
        return gym.canManageGym(userId: userId)
    }
    
    /// Get user's role for a specific gym
    static func getUserRole(userId: String, gymId: String) -> String {
        guard let gym = gyms.first(where: { $0.id == gymId }) else { return "None" }
        
        if gym.isOwner(userId: userId) {
            return "Owner"
        } else if gym.isStaff(userId: userId) {
            return "Staff"
        } else {
            return "Member"
        }
    }
    
    /// Get all gyms a user can manage (owner or staff)
    static func getGymsForUser(userId: String) -> [Gym] {
        return gyms.filter { gym in
            gym.canManageGym(userId: userId)
        }
    }
    
    /// Get events created by a specific user
    static func getEventsCreatedBy(userId: String) -> [EventItem] {
        return events.filter { $0.author.id == userId }
    }
    
    /// Get events for a specific gym
    static func getEventsForGym(gymId: String) -> [EventItem] {
        return events.filter { $0.host.id == gymId }
    }
    
    /// Get all media items for a specific event
    static func getMediaForEvent(eventId: String) -> [MediaItem] {
        guard let event = events.first(where: { $0.id == eventId }) else { return [] }
        return event.mediaItems ?? []
    }
    
    /// Get profile image for a specific gym
    static func getGymProfileImage(gymId: String) -> MediaItem? {
        guard let gym = gyms.first(where: { $0.id == gymId }) else { return nil }
        return gym.profileImage
    }
    
    /// Get events with media
    static func getEventsWithMedia() -> [EventItem] {
        return events.filter { $0.mediaItems != nil && !$0.mediaItems!.isEmpty }
    }
    
    /// Get gyms with profile images
    static func getGymsWithImages() -> [Gym] {
        return gyms.filter { $0.profileImage != nil }
    }
}
