//
//  Gym.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

struct Gym: Identifiable, Equatable, Hashable {
    // Gym fundamentals
    var id: String
    var name: String
    var companyId: String?
    var description: String?
    var location: LocationData
    var climbingType: [ClimbingTypes]
    var amenities: [Amenities]
    var events: [String]
    var profileImage: MediaItem?
    var createdAt: Date

    // Verification status for gym approval process
    var verificationStatus: GymVerificationStatus
    var verificationNotes: String?
    var verifiedAt: Date?
    var verifiedBy: String?

    // Gym operating info
    var operatingHours: GymOperatingHours?
    var website: String?
    var email: String
    var phoneNumber: String?
    
    
    init(id: String, name: String, companyId: String? = nil, description: String?, location: LocationData, climbingType: [ClimbingTypes], amenities: [Amenities], events: [String], profileImage: MediaItem?, createdAt: Date, verificationStatus: GymVerificationStatus = .pending, verificationNotes: String? = nil, verifiedAt: Date? = nil, verifiedBy: String? = nil, operatingHours: GymOperatingHours?, website: String? = nil, email: String, phoneNumber: String? = nil) {
        self.id = id
        self.name = name
        self.companyId = companyId
        self.description = description
        self.location = location
        self.climbingType = climbingType
        self.amenities = amenities
        self.events = events
        self.profileImage = profileImage
        self.createdAt = createdAt
        self.verificationStatus = verificationStatus
        self.verificationNotes = verificationNotes
        self.verifiedAt = verifiedAt
        self.verifiedBy = verifiedBy
        self.operatingHours = operatingHours
        self.website = website
        self.email = email
        self.phoneNumber = phoneNumber
    }
    
    // Verification status checks
    var isLive: Bool {
        return verificationStatus == .approved
    }
    
    var isPendingVerification: Bool {
        return verificationStatus == .pending
    }
    
    var isRejected: Bool {
        return verificationStatus == .rejected
    }
    
    
    // Verification status management
    func updatingVerificationStatus(_ status: GymVerificationStatus, notes: String? = nil, verifiedBy: String? = nil) -> Gym {
        return Gym(
            id: id, name: name, companyId: companyId, description: description,
            location: location, climbingType: climbingType, amenities: amenities,
            events: events, profileImage: profileImage, createdAt: createdAt,
            verificationStatus: status,
            verificationNotes: notes, verifiedAt: status != .pending ? Date() : nil, verifiedBy: verifiedBy,
            operatingHours: operatingHours, website: website, email: email, phoneNumber: phoneNumber
        )
    }
}

// MARK: - Verification Status Enum
enum GymVerificationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Verification"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Gym staff & management permissions

struct GymAdministrator: Identifiable, Codable {
    let id: String
    let userId: String
    let gymId: String
    let role: AdminRole
    let addedAt: Date
    let addedBy: String
    
    enum AdminRole: String, Codable {
        case owner
        case admin
        case manager
    }
}

// Simple staff info for display purposes
struct StaffMember: Identifiable {
    let id: String
    let name: String
    let email: String
    let addedAt: Date
    
    init(user: User, addedAt: Date = Date()) {
        self.id = user.id
        self.name = "\(user.firstName) \(user.lastName)"
        self.email = user.email
        self.addedAt = addedAt
    }
}

// MARK: - Gym facilities
enum ClimbingTypes: String, Codable, CaseIterable, Hashable {
    case bouldering
    case sport
    case board
    case gym
}

enum Amenities: String, Codable, CaseIterable, Hashable {
    case showers = "Showers"
    case lockers = "Lockers"
    case bar = "Bar"
    case food = "Food"
    case changingRooms = "Changing Rooms"
    case bathrooms = "Bathrooms"
    case cafe = "Cafe"
    case bikeStorage = "Bike Storage"
    case workSpace = "Work Space"
    case shop = "Gear Shop"
    case wifi = "Wifi"
}

struct GymFavorite: Identifiable, Codable, Equatable {
    let userId: String
    let gymId: String
    
    var id: String {
        return "\(userId)-\(gymId)"
    }
}

//MARK: - Gym operating hours

struct GymOperatingHours: Codable, Equatable, Hashable {
    var monday: DayHours?
    var tuesday: DayHours?
    var wednesday: DayHours?
    var thursday: DayHours?
    var friday: DayHours?
    var saturday: DayHours?
    var sunday: DayHours?
    
    struct DayHours: Codable, Equatable, Hashable {
        var open: String  // Format: "HH:mm" (24-hour)
        var close: String // Format: "HH:mm" (24-hour)
        var isClosed: Bool
        var offPeakPeriods: [TimePeriod] // Optional off-peak times
        
        init(open: String = "09:00", close: String = "22:00", isClosed: Bool = false, offPeakPeriods: [TimePeriod] = []) {
            self.open = open
            self.close = close
            self.isClosed = isClosed
            self.offPeakPeriods = offPeakPeriods
        }
        
        struct TimePeriod: Codable, Equatable, Hashable, Identifiable {
            var id: String
            var startTime: String // Format: "HH:mm"
            var endTime: String   // Format: "HH:mm"
            
            init(id: String = UUID().uuidString, startTime: String, endTime: String) {
                self.id = id
                self.startTime = startTime
                self.endTime = endTime
            }
        }
        
        // Check if current time is off-peak
        func isCurrentlyOffPeak() -> Bool {
            guard !isClosed, !offPeakPeriods.isEmpty else { return false }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let nowString = formatter.string(from: Date())
            
            for period in offPeakPeriods {
                if nowString >= period.startTime && nowString < period.endTime {
                    return true
                }
            }
            
            return false
        }
        
        var hasOffPeakTimes: Bool {
            !offPeakPeriods.isEmpty
        }
    }
    
    // Helper to check if gym is currently open
    func isCurrentlyOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        
        guard let todayHours = hoursForWeekday(weekday),
              !todayHours.isClosed else {
            return false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let nowString = formatter.string(from: now)
        
        return nowString >= todayHours.open && nowString < todayHours.close
    }
    
    // Check if currently off-peak
    func isCurrentlyOffPeak() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        guard let todayHours = hoursForWeekday(weekday) else {
            return false
        }
        
        return todayHours.isCurrentlyOffPeak()
    }
    
    func hoursForWeekday(_ weekday: Int) -> DayHours? {
        switch weekday {
        case 1: return sunday
        case 2: return monday
        case 3: return tuesday
        case 4: return wednesday
        case 5: return thursday
        case 6: return friday
        case 7: return saturday
        default: return nil
        }
    }
    
    var hasAnyOffPeakTimes: Bool {
        let allDays = [monday, tuesday, wednesday, thursday, friday, saturday, sunday]
        return allDays.contains { $0?.hasOffPeakTimes == true }
    }
}

//MARK: - Placeholder for event codable
extension Gym {
    /// Creates a minimal placeholder Gym with just an ID for use in relationships
    static func placeholder(id: String) -> Gym {
        return Gym(
            id: id,
            name: "Loading...",
            companyId: nil,
            description: nil,
            location: LocationData(latitude: 0, longitude: 0, address: nil),
            climbingType: [],
            amenities: [],
            events: [],
            profileImage: nil,
            createdAt: Date(),
            operatingHours: nil,
            website: nil,
            email: "",
            phoneNumber: nil
        )
    }
}
