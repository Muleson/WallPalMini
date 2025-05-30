//
//  SampleData.swift
//  GriGriMVP
//
//  Created by Sam Quested on 13/05/2025.
//

import Foundation

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
            url: URL(string: "https://images.unsplash.com/photo-1522163182402-834f871fd851")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1645000000),
            ownerId: "gym1"
        ),
        MediaItem(
            id: "media2",
            url: URL(string: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1646000000),
            ownerId: "gym2"
        ),
        MediaItem(
            id: "media3",
            url: URL(string: "https://images.unsplash.com/photo-1564769662533-4f00a87b4056")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1647000000),
            ownerId: "gym3"
        ),
        MediaItem(
            id: "media4",
            url: URL(string: "https://images.unsplash.com/photo-1507034589631-9433cc6bc453")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1648000000),
            ownerId: "event1"
        ),
        MediaItem(
            id: "media5",
            url: URL(string: "https://images.unsplash.com/photo-1519904981063-b0cf448d479e")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1649000000),
            ownerId: "event2"
        ),
        MediaItem(
            id: "media6",
            url: URL(string: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1650000000),
            ownerId: "event4"
        ),
        MediaItem(
            id: "media7",
            url: URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1651000000),
            ownerId: "event1"
        ),
        MediaItem(
            id: "media8",
            url: URL(string: "https://images.unsplash.com/photo-1544551763-46a013bb70d5")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1652000000),
            ownerId: "event2"
        )
    ]
    
    // MARK: - Gyms with MediaItem Profile Images
    static let gyms = [
        Gym(
            id: "gym1",
            email: "info@boulderworld.com",
            name: "Boulder World",
            description: "Premier bouldering facility with 200+ problems ranging from beginner to expert",
            location: LocationData(
                latitude: 51.5074,
                longitude: -0.1278,
                address: "123 Climb Street, London"
            ),
            climbingType: [.bouldering, .topRope],
            amenities: ["Cafe", "Training Area", "Changing Rooms", "Showers"],
            events: ["event1", "event3"],
            profileImage: mediaItems[0], // Uses media1
            createdAt: Date(timeIntervalSince1970: 1610000000),
            ownerId: "user1", // John Doe is the owner
            staffUserIds: ["user2", "user4"] // Jane and Sarah are staff
        ),
        Gym(
            id: "gym2",
            email: "contact@verticaledge.com",
            name: "Vertical Edge",
            description: "Indoor lead and top rope climbing center with routes for all abilities",
            location: LocationData(
                latitude: 53.4808,
                longitude: -2.2426,
                address: "456 Rock Avenue, Manchester"
            ),
            climbingType: [.lead, .topRope],
            amenities: ["Pro Shop", "Gym", "Sauna"],
            events: ["event2"],
            profileImage: mediaItems[1], // Uses media2
            createdAt: Date(timeIntervalSince1970: 1615000000),
            ownerId: "user2", // Jane Smith is the owner
            staffUserIds: ["user3", "user5"] // Alex and Mike are staff
        ),
        Gym(
            id: "gym3",
            email: "hello@cragclimb.com",
            name: "Crag Climb",
            description: "Family-friendly climbing center with bouldering and walls for all ages",
            location: LocationData(
                latitude: 51.4545,
                longitude: -2.5879,
                address: "789 Chalk Road, Bristol"
            ),
            climbingType: [.bouldering, .lead, .topRope],
            amenities: ["Kids Area", "Coaching", "Birthday Packages"],
            events: [],
            profileImage: mediaItems[2], // Uses media3
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
            host: gyms[0], // Boulder World
            name: "Summer Send Festival",
            type: .competition,
            location: "Boulder World, Main Hall",
            description: "Annual bouldering competition with categories for all levels. Cash prizes for top finishers!",
            mediaItems: [mediaItems[3], mediaItems[6]], // Multiple images for this event
            registrationLink: "https://example.com/register-summer-send",
            createdAt: Date(timeIntervalSince1970: 1650000000),
            eventDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            isFeatured: true,
            registrationRequired: true
        ),
        EventItem(
            id: "event2",
            author: users[1], // Jane Smith (owner of Vertical Edge)
            host: gyms[1], // Vertical Edge
            name: "Beginner Workshop",
            type: .openDay,
            location: "Vertical Edge, Training Area",
            description: "Learn the basics of climbing in this introductory session. Equipment provided.",
            mediaItems: [mediaItems[4], mediaItems[7]], // Multiple images for this event
            registrationLink: "https://example.com/register-workshop",
            createdAt: Date(timeIntervalSince1970: 1655000000),
            eventDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
            isFeatured: false,
            registrationRequired: false
        ),
        EventItem(
            id: "event3",
            author: users[3], // Sarah Johnson (staff at Boulder World)
            host: gyms[0], // Boulder World
            name: "Route Setting Showcase",
            type: .settingTaster,
            location: "Boulder World",
            description: "Come see our new routes and boulder problems set by guest setter Alex Megos!",
            mediaItems: nil, // No images for this event
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1660000000),
            eventDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            isFeatured: true,
            registrationRequired: false
        ),
        EventItem(
            id: "event4",
            author: users[2], // Alex Wilson (owner of Crag Climb)
            host: gyms[2], // Crag Climb
            name: "Grand Opening",
            type: .opening,
            location: "Crag Climb",
            description: "Join us for the grand opening of our new facility! Free climbing all day and prizes.",
            mediaItems: [mediaItems[5]], // Single image for this event
            registrationLink: "https://example.com/grand-opening",
            createdAt: Date(timeIntervalSince1970: 1665000000),
            eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
            isFeatured: true,
            registrationRequired: true
        ),
        EventItem(
            id: "event5",
            author: users[4], // Mike Brown (staff at Vertical Edge)
            host: gyms[1], // Vertical Edge
            name: "Youth Climbing Club",
            type: .social,
            location: "Vertical Edge",
            description: "Weekly climbing sessions for young climbers aged 8-16. Build skills and make friends!",
            mediaItems: nil, // No images for this event
            registrationLink: "https://example.com/youth-club",
            createdAt: Date(timeIntervalSince1970: 1670000000),
            eventDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            isFeatured: false,
            registrationRequired: true
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
