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
             favouriteGyms: ["gym1", "gym3"]
         ),
         User(
             id: "user2",
             email: "jane.smith@example.com",
             firstName: "Jane",
             lastName: "Smith",
             createdAt: Date(timeIntervalSince1970: 1625000000),
             favouriteGyms: ["gym2"]
         ),
         User(
             id: "user3",
             email: "alex.wilson@example.com",
             firstName: "Alex",
             lastName: "Wilson",
             createdAt: Date(timeIntervalSince1970: 1630000000),
             favouriteGyms: nil
         )
     ]
     
     // MARK: - Gyms
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
                 imageUrl: URL(string: "https://images.unsplash.com/photo-1522163182402-834f871fd851"),
                 createdAt: Date(timeIntervalSince1970: 1610000000)
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
                 imageUrl: URL(string: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4"),
                 createdAt: Date(timeIntervalSince1970: 1615000000)
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
                 imageUrl: URL(string: "https://images.unsplash.com/photo-1522163182402-834f871fd851"),
                 createdAt: Date(timeIntervalSince1970: 1620000000)
             )
         ]
    
    // MARK: - Media Items
     static let mediaItems = [
         MediaItem(
             id: "media1",
             url: URL(string: "https://images.unsplash.com/photo-1522163182402-834f871fd851")!,
             type: .image,
             uploadedAt: Date(timeIntervalSince1970: 1645000000),
             ownerId: "user1"
         ),
         MediaItem(
             id: "media2",
             url: URL(string: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4")!,
             type: .image,
             uploadedAt: Date(timeIntervalSince1970: 1646000000),
             ownerId: "gym1"
         ),
         MediaItem(
             id: "media3",
             url: URL(string: "https://images.unsplash.com/photo-1564769662533-4f00a87b4056")!,
             type: .image,
             uploadedAt: Date(timeIntervalSince1970: 1647000000),
             ownerId: "gym2"
         ),
         MediaItem(
             id: "media4",
             url: URL(string: "https://images.unsplash.com/photo-1507034589631-9433cc6bc453")!,
             type: .image,
             uploadedAt: Date(timeIntervalSince1970: 1648000000),
             ownerId: "user2"
         ),
         MediaItem(
             id: "media5",
             url: URL(string: "https://images.unsplash.com/photo-1519904981063-b0cf448d479e")!,
             type: .image,
             uploadedAt: Date(timeIntervalSince1970: 1649000000),
             ownerId: "gym3"
         )
     ]
    
    // MARK: - Events
     static let events = [
         EventItem(
             id: "event1",
             author: users[0],
             host: gyms[0],
             name: "Summer Send Festival",
             type: .competition,
             location: "Boulder World, Main Hall",
             description: "Annual bouldering competition with categories for all levels. Cash prizes for top finishers!",
             mediaItems: [mediaItems[0]],
             registrationLink: "https://example.com/register-summer-send",
             createdAt: Date(timeIntervalSince1970: 1650000000),
             eventDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
             isFeatured: true
         ),
         EventItem(
             id: "event2",
             author: users[1],
             host: gyms[1],
             name: "Beginner Workshop",
             type: .openDay,
             location: "Vertical Edge, Training Area",
             description: "Learn the basics of climbing in this introductory session. Equipment provided.",
             mediaItems: [mediaItems[1]],
             registrationLink: "https://example.com/register-workshop",
             createdAt: Date(timeIntervalSince1970: 1655000000),
             eventDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
             isFeatured: false
         ),
         EventItem(
             id: "event3",
             author: users[0],
             host: gyms[0],
             name: "Route Setting Showcase",
             type: .settingTaster,
             location: "Boulder World",
             description: "Come see our new routes and boulder problems set by guest setter Alex Megos!",
             mediaItems: nil,
             registrationLink: nil,
             createdAt: Date(timeIntervalSince1970: 1660000000),
             eventDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
             isFeatured: true
         ),
         EventItem(
             id: "event4",
             author: users[2],
             host: gyms[2],
             name: "Grand Opening",
             type: .opening,
             location: "Crag Climb",
             description: "Join us for the grand opening of our new facility! Free climbing all day and prizes.",
             mediaItems: [mediaItems[2]],
             registrationLink: "https://example.com/grand-opening",
             createdAt: Date(timeIntervalSince1970: 1665000000),
             eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
             isFeatured: true
         )
     ]
}


