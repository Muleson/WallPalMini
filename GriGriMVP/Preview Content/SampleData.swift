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
        ),
        
        // Additional logos for new gyms
        MediaItem(
            id: "media12",
            url: URL(string: "local-asset://SampleLogo5")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1654000000),
            ownerId: "gym5"
        ),
        MediaItem(
            id: "media13",
            url: URL(string: "local-asset://SampleLogo6")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1655000000),
            ownerId: "gym6"
        ),
        MediaItem(
            id: "media14",
            url: URL(string: "local-asset://SampleLogo7")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1656000000),
            ownerId: "gym7"
        ),
        
        // Additional posters for new events
        MediaItem(
            id: "media15",
            url: URL(string: "local-asset://SamplePoster5")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1657000000),
            ownerId: "event_poster1"
        ),
        MediaItem(
            id: "media16",
            url: URL(string: "local-asset://SamplePoster6")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1658000000),
            ownerId: "event_poster2"
        ),
        MediaItem(
            id: "media17",
            url: URL(string: "local-asset://SamplePoster7")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1659000000),
            ownerId: "event_poster3"
        ),
        MediaItem(
            id: "media18",
            url: URL(string: "local-asset://SamplePoster8")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1660000000),
            ownerId: "event_poster4"
        ),
        MediaItem(
            id: "media19",
            url: URL(string: "local-asset://SamplePoster9")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1661000000),
            ownerId: "event_poster5"
        ),
        MediaItem(
            id: "media20",
            url: URL(string: "local-asset://SamplePoster10")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1662000000),
            ownerId: "event_poster6"
        ),
        MediaItem(
            id: "media21",
            url: URL(string: "local-asset://SamplePoster11")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1663000000),
            ownerId: "event_poster7"
        ),
        MediaItem(
            id: "media22",
            url: URL(string: "local-asset://SamplePoster12")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1664000000),
            ownerId: "event_poster8"
        ),
        MediaItem(
            id: "media23",
            url: URL(string: "local-asset://SamplePoster13")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1665000000),
            ownerId: "event_poster9"
        ),
        MediaItem(
            id: "media24",
            url: URL(string: "local-asset://SamplePoster14")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1666000000),
            ownerId: "event_poster10"
        ),
        MediaItem(
            id: "media25",
            url: URL(string: "local-asset://SamplePoster15")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1667000000),
            ownerId: "event_poster11"
        ),
        MediaItem(
            id: "media26",
            url: URL(string: "local-asset://SamplePoster16")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1668000000),
            ownerId: "event_poster12"
        ),
        MediaItem(
            id: "media27",
            url: URL(string: "local-asset://SamplePoster17")!,
            type: .image,
            uploadedAt: Date(timeIntervalSince1970: 1669000000),
            ownerId: "event_poster13"
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
            verificationStatus: .approved,
            verificationNotes: "Excellent facility meeting all requirements",
            verifiedAt: Date(timeIntervalSince1970: 1610086400),
            verifiedBy: "admin1"
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
            verificationStatus: .approved,
            verificationNotes: "Professional climbing facility with safety standards met",
            verifiedAt: Date(timeIntervalSince1970: 1615086400),
            verifiedBy: "admin1"
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
            verificationStatus: .approved,
            verificationNotes: "Family-friendly facility with excellent safety measures",
            verifiedAt: Date(timeIntervalSince1970: 1620086400),
            verifiedBy: "admin2"
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
            profileImage: mediaItems[3], // Uses media4
            createdAt: Date(timeIntervalSince1970: 1620000000),
            verificationStatus: .approved,
            verificationNotes: "Unique and beautiful climbing facility in historic building",
            verifiedAt: Date(timeIntervalSince1970: 1620172800),
            verifiedBy: "admin2"
        ),
        
        // New gyms using additional logos
        Gym(
            id: "gym5",
            email: "info@peakperformance.com",
            name: "Peak Performance",
            description: "High-altitude training facility focusing on advanced climbing techniques",
            location: LocationData(
                latitude: 51.4994,
                longitude: -0.1270,
                address: "42 Summit Lane, London"
            ),
            climbingType: [.sport, .bouldering, .board],
            amenities: [.shop, .cafe, .workSpace],
            events: [],
            profileImage: mediaItems[12], // Uses media12 (SampleLogo5)
            createdAt: Date(timeIntervalSince1970: 1625000000),
            verificationStatus: .approved,
            verificationNotes: "Modern facility with excellent training equipment",
            verifiedAt: Date(timeIntervalSince1970: 1625086400),
            verifiedBy: "admin1"
        ),
        Gym(
            id: "gym6",
            email: "hello@climbhigh.co.uk",
            name: "Northern Rocks",
            description: "Community-focused climbing center with routes for every skill level",
            location: LocationData(
                latitude: 51.5155,
                longitude: -0.0922,
                address: "78 Ascent Street, London"
            ),
            climbingType: [.bouldering, .gym, .sport],
            amenities: [.changingRooms, .lockers, .cafe, .wifi],
            events: [],
            profileImage: mediaItems[13], // Uses media13 (SampleLogo6)
            createdAt: Date(timeIntervalSince1970: 1630000000),
            verificationStatus: .approved,
            verificationNotes: "Excellent community programs and beginner-friendly environment",
            verifiedAt: Date(timeIntervalSince1970: 1630086400),
            verifiedBy: "admin2"
        ),
        Gym(
            id: "gym7",
            email: "contact@urbanclimb.com",
            name: "Urban Climb",
            description: "Modern urban climbing facility with cutting-edge route setting",
            location: LocationData(
                latitude: 51.5311,
                longitude: -0.1611,
                address: "156 City Heights, London"
            ),
            climbingType: [.bouldering, .sport, .board],
            amenities: [.showers, .shop, .food, .workSpace],
            events: [],
            profileImage: mediaItems[14], // Uses media14 (SampleLogo7)
            createdAt: Date(timeIntervalSince1970: 1635000000),
            verificationStatus: .approved,
            verificationNotes: "Innovative route setting and modern facilities",
            verifiedAt: Date(timeIntervalSince1970: 1635086400),
            verifiedBy: "admin1"
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
        ),
        
        // Additional .gymClass events without media
        EventItem(
            id: "event_class9",
            author: users[1], // Jane Smith
            host: gyms[4], // Peak Performance
            name: "Advanced Boulder Training",
            eventType: .gymClass,
            climbingType: [.bouldering],
            location: "Peak Performance, Training Wall",
            description: "High-intensity bouldering sessions for experienced climbers. Focus on dynamic movements and power endurance.",
            mediaItems: nil,
            registrationLink: "https://peakperformance.com/advanced-boulder",
            createdAt: Date(timeIntervalSince1970: 1679000000),
            startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!.addingTimeInterval(19 * 3600), // 7 PM, 3 days from now
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!.addingTimeInterval(21 * 3600), // 2 hour class
            isFeatured: false,
            registrationRequired: true,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())
        ),
        
        EventItem(
            id: "event_class10",
            author: users[3], // Sarah Johnson
            host: gyms[5], // Climb High
            name: "Teen Climbing Academy",
            eventType: .gymClass,
            climbingType: [.bouldering, .sport],
            location: "Climb High, Youth Area",
            description: "Weekly climbing sessions for teenagers aged 13-18. Develop skills, strength, and confidence in a supportive environment.",
            mediaItems: nil,
            registrationLink: "https://climbhigh.co.uk/teen-academy",
            createdAt: Date(timeIntervalSince1970: 1680000000),
            startDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!.addingTimeInterval(17 * 3600), // 5 PM Friday
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!.addingTimeInterval(18.5 * 3600), // 1.5 hour class
            isFeatured: true,
            registrationRequired: true,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        ),
        
        EventItem(
            id: "event_class11",
            author: users[4], // Mike Brown
            host: gyms[6], // Urban Climb
            name: "Morning Power Hour",
            eventType: .gymClass,
            climbingType: [.bouldering, .board],
            location: "Urban Climb, Training Zone",
            description: "Early morning high-intensity training focusing on power and coordination. Perfect for working professionals.",
            mediaItems: nil,
            registrationLink: nil, // Drop-in class
            createdAt: Date(timeIntervalSince1970: 1681000000),
            startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(7 * 3600), // 7 AM tomorrow
            endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(8 * 3600), // 1 hour class
            isFeatured: false,
            registrationRequired: false,
            frequency: .daily,
            recurrenceEndDate: Calendar.current.date(byAdding: .month, value: 12, to: Date())
        ),
        
        // .social events without media
        EventItem(
            id: "event_social1",
            author: users[0], // John Doe
            host: gyms[4], // Peak Performance
            name: "Friday Night Climb & Chill",
            eventType: .social,
            climbingType: [.bouldering, .sport],
            location: "Peak Performance, Main Area",
            description: "End the week with relaxed climbing and good company. All levels welcome, snacks provided!",
            mediaItems: nil,
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1682000000),
            startDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!.addingTimeInterval(18 * 3600), // 6 PM Friday
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!.addingTimeInterval(21 * 3600), // 3 hours
            isFeatured: false,
            registrationRequired: false,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())
        ),
        
        EventItem(
            id: "event_social2",
            author: users[2], // Alex Wilson
            host: gyms[5], // Climb High
            name: "Women's Climbing Circle",
            eventType: .social,
            climbingType: [.bouldering],
            location: "Climb High, Community Space",
            description: "A supportive space for women and non-binary climbers to connect, share beta, and climb together.",
            mediaItems: nil,
            registrationLink: "https://climbhigh.co.uk/womens-circle",
            createdAt: Date(timeIntervalSince1970: 1683000000),
            startDate: Calendar.current.date(byAdding: .day, value: 9, to: Date())!.addingTimeInterval(18.5 * 3600), // 6:30 PM
            endDate: Calendar.current.date(byAdding: .day, value: 9, to: Date())!.addingTimeInterval(20.5 * 3600), // 2 hours
            isFeatured: true,
            registrationRequired: true,
            frequency: .biweekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        ),
        
        EventItem(
            id: "event_social3",
            author: users[1], // Jane Smith
            host: gyms[6], // Urban Climb
            name: "Sunday Family Climbing",
            eventType: .social,
            climbingType: [.gym, .bouldering],
            location: "Urban Climb, Family Area",
            description: "Bring the whole family for a fun climbing session. Special rates for families and activities for kids.",
            mediaItems: nil,
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1684000000),
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!.addingTimeInterval(14 * 3600), // 2 PM Sunday
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!.addingTimeInterval(17 * 3600), // 3 hours
            isFeatured: false,
            registrationRequired: false,
            frequency: .weekly,
            recurrenceEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        ),
        
        // Events with poster media (SamplePoster5-17)
        EventItem(
            id: "event_poster1",
            author: users[0], // John Doe
            host: gyms[0], // Rock Valley
            name: "Spring Bouldering Championship",
            eventType: .competition,
            climbingType: [.bouldering],
            location: "Rock Valley, Competition Area",
            description: "Annual spring bouldering competition with prizes for all categories. Registration includes lunch and event t-shirt.",
            mediaItems: [mediaItems[15]], // SamplePoster5
            registrationLink: "https://rockvalley.com/spring-comp",
            createdAt: Date(timeIntervalSince1970: 1685000000),
            startDate: Calendar.current.date(byAdding: .day, value: 21, to: Date())!.addingTimeInterval(9 * 3600), // 9 AM, 3 weeks from now
            endDate: Calendar.current.date(byAdding: .day, value: 21, to: Date())!.addingTimeInterval(17 * 3600), // All day event
            isFeatured: true,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster2",
            author: users[1], // Jane Smith
            host: gyms[1], // The Vault
            name: "Open House Weekend",
            eventType: .openDay,
            climbingType: [.sport, .bouldering],
            location: "The Vault, All Areas",
            description: "Come explore our facility! Free climbing for first-time visitors, gear demos, and meet our instructors.",
            mediaItems: [mediaItems[16]], // SamplePoster6
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1686000000),
            startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!.addingTimeInterval(10 * 3600), // 10 AM, 2 weeks from now
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!.addingTimeInterval(18 * 3600), // Weekend event
            isFeatured: true,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster3",
            author: users[2], // Alex Wilson
            host: gyms[2], // Gravity Climbing
            name: "New Route Setting Preview",
            eventType: .settingTaster,
            climbingType: [.bouldering, .sport],
            location: "Gravity Climbing, Main Wall",
            description: "Be the first to try our brand new routes! Join us for an exclusive preview with the route setters.",
            mediaItems: [mediaItems[17]], // SamplePoster7
            registrationLink: "https://gravity.com/new-routes",
            createdAt: Date(timeIntervalSince1970: 1687000000),
            startDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!.addingTimeInterval(18 * 3600), // 6 PM
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!.addingTimeInterval(21 * 3600), // 3 hours
            isFeatured: false,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster4",
            author: users[3], // Sarah Johnson
            host: gyms[3], // The Church
            name: "Grand Reopening Celebration",
            eventType: .opening,
            climbingType: [.bouldering, .sport],
            location: "The Church, All Areas",
            description: "Join us for our grand reopening after renovations! Free climbing all day, food trucks, and live music.",
            mediaItems: [mediaItems[18]], // SamplePoster8
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1688000000),
            startDate: Calendar.current.date(byAdding: .day, value: 28, to: Date())!.addingTimeInterval(10 * 3600), // 10 AM, 4 weeks from now
            endDate: Calendar.current.date(byAdding: .day, value: 28, to: Date())!.addingTimeInterval(22 * 3600), // 12 hour celebration
            isFeatured: true,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster5",
            author: users[4], // Mike Brown
            host: gyms[4], // Peak Performance
            name: "Elite Training Camp",
            eventType: .competition,
            climbingType: [.bouldering, .sport],
            location: "Peak Performance, Training Facility",
            description: "Intensive 3-day training camp for competitive climbers. Limited spots available.",
            mediaItems: [mediaItems[19]], // SamplePoster9
            registrationLink: "https://peakperformance.com/elite-camp",
            createdAt: Date(timeIntervalSince1970: 1689000000),
            startDate: Calendar.current.date(byAdding: .day, value: 35, to: Date())!.addingTimeInterval(9 * 3600), // 9 AM, 5 weeks from now
            endDate: Calendar.current.date(byAdding: .day, value: 37, to: Date())!.addingTimeInterval(17 * 3600), // 3-day event
            isFeatured: true,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster6",
            author: users[0], // John Doe
            host: gyms[5], // Climb High
            name: "Community Open Day",
            eventType: .openDay,
            climbingType: [.bouldering, .gym],
            location: "Climb High, Community Space",
            description: "Free community climbing day! Bring friends and family to experience climbing in a welcoming environment.",
            mediaItems: [mediaItems[20]], // SamplePoster10
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1690000000),
            startDate: Calendar.current.date(byAdding: .day, value: 17, to: Date())!.addingTimeInterval(12 * 3600), // 12 PM
            endDate: Calendar.current.date(byAdding: .day, value: 17, to: Date())!.addingTimeInterval(18 * 3600), // 6 hours
            isFeatured: false,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster7",
            author: users[1], // Jane Smith
            host: gyms[6], // Urban Climb
            name: "Setter's Special: Beta Testing",
            eventType: .settingTaster,
            climbingType: [.bouldering, .board],
            location: "Urban Climb, Beta Wall",
            description: "Help our setters test new problems! Your feedback shapes our future routes.",
            mediaItems: [mediaItems[21]], // SamplePoster11
            registrationLink: "https://urbanclimb.com/beta-test",
            createdAt: Date(timeIntervalSince1970: 1691000000),
            startDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!.addingTimeInterval(19 * 3600), // 7 PM
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!.addingTimeInterval(21 * 3600), // 2 hours
            isFeatured: false,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster8",
            author: users[2], // Alex Wilson
            host: gyms[0], // Rock Valley (spreading across gyms)
            name: "Autumn Climbing Festival",
            eventType: .competition,
            climbingType: [.bouldering, .sport],
            location: "Rock Valley, Festival Grounds",
            description: "Multi-day climbing festival with competitions, workshops, and vendor village. The biggest climbing event of the year!",
            mediaItems: [mediaItems[22]], // SamplePoster12
            registrationLink: "https://rockvalley.com/autumn-festival",
            createdAt: Date(timeIntervalSince1970: 1692000000),
            startDate: Calendar.current.date(byAdding: .day, value: 45, to: Date())!.addingTimeInterval(8 * 3600), // 8 AM
            endDate: Calendar.current.date(byAdding: .day, value: 47, to: Date())!.addingTimeInterval(20 * 3600), // 3-day festival
            isFeatured: true,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster9",
            author: users[3], // Sarah Johnson
            host: gyms[1], // The Vault
            name: "New Member Open House",
            eventType: .openDay,
            climbingType: [.sport, .bouldering],
            location: "The Vault, Welcome Center",
            description: "Special rates for new members! Tour the facility, meet our staff, and start your climbing journey.",
            mediaItems: [mediaItems[23]], // SamplePoster13
            registrationLink: "https://thevault.com/new-member",
            createdAt: Date(timeIntervalSince1970: 1693000000),
            startDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!.addingTimeInterval(16 * 3600), // 4 PM
            endDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!.addingTimeInterval(20 * 3600), // 4 hours
            isFeatured: false,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster10",
            author: users[4], // Mike Brown
            host: gyms[2], // Gravity Climbing
            name: "Route Setting Workshop",
            eventType: .settingTaster,
            climbingType: [.bouldering],
            location: "Gravity Climbing, Setting Area",
            description: "Learn the art of route setting! Hands-on workshop with our experienced setters.",
            mediaItems: [mediaItems[24]], // SamplePoster14
            registrationLink: "https://gravity.com/setting-workshop",
            createdAt: Date(timeIntervalSince1970: 1694000000),
            startDate: Calendar.current.date(byAdding: .day, value: 19, to: Date())!.addingTimeInterval(13 * 3600), // 1 PM
            endDate: Calendar.current.date(byAdding: .day, value: 19, to: Date())!.addingTimeInterval(17 * 3600), // 4 hours
            isFeatured: true,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster11",
            author: users[0], // John Doe
            host: gyms[3], // The Church
            name: "New Wing Grand Opening",
            eventType: .opening,
            climbingType: [.bouldering, .sport, .board],
            location: "The Church, New Wing",
            description: "Celebrate the opening of our brand new climbing wing! Extended hours and special programming all week.",
            mediaItems: [mediaItems[25]], // SamplePoster15
            registrationLink: nil,
            createdAt: Date(timeIntervalSince1970: 1695000000),
            startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!.addingTimeInterval(9 * 3600), // 9 AM
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!.addingTimeInterval(21 * 3600), // 12 hours
            isFeatured: true,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster12",
            author: users[1], // Jane Smith
            host: gyms[4], // Peak Performance
            name: "Winter Skills Competition",
            eventType: .competition,
            climbingType: [.bouldering, .sport],
            location: "Peak Performance, Competition Arena",
            description: "Technical climbing competition focusing on precision and problem-solving skills. Categories for all levels.",
            mediaItems: [mediaItems[26]], // SamplePoster16
            registrationLink: "https://peakperformance.com/winter-comp",
            createdAt: Date(timeIntervalSince1970: 1696000000),
            startDate: Calendar.current.date(byAdding: .day, value: 60, to: Date())!.addingTimeInterval(10 * 3600), // 10 AM
            endDate: Calendar.current.date(byAdding: .day, value: 60, to: Date())!.addingTimeInterval(18 * 3600), // 8 hours
            isFeatured: true,
            registrationRequired: true,
            frequency: .oneTime,
            recurrenceEndDate: nil
        ),
        
        EventItem(
            id: "event_poster13",
            author: users[2], // Alex Wilson
            host: gyms[5], // Climb High
            name: "Innovation in Climbing Class",
            eventType: .gymClass,
            climbingType: [.bouldering, .sport, .board],
            location: "Climb High, Innovation Lab",
            description: "Explore the future of climbing! Try new holds, interactive walls, and cutting-edge training tools.",
            mediaItems: [], // SamplePoster17
            registrationLink: "https://climbhigh.co.uk/innovation-day",
            createdAt: Date(timeIntervalSince1970: 1697000000),
            startDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())!.addingTimeInterval(11 * 3600), // 11 AM
            endDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())!.addingTimeInterval(19 * 3600), // 8 hours
            isFeatured: false,
            registrationRequired: false,
            frequency: .oneTime,
            recurrenceEndDate: nil
        )
      
    ]
    
    // MARK: - Helper Methods
    
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
