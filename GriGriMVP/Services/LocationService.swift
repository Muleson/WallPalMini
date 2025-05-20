//
//  LocationService.swift
//  GriGriMVP
//
//  Created by Sam Quested on 14/05/2025.
//

import Foundation
import CoreLocation

class LocationService {
    static let shared = LocationService()
    
    private init() {}
    
    // MARK: - Basic Location Operations
    
    func distance(from userLocation: CLLocation, to locationData: LocationData) -> Double {
        let eventLocation = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
        return userLocation.distance(from: eventLocation)
    }
    
    func createCLLocation(from locationData: LocationData) -> CLLocation {
        return CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
    }
    
    // MARK: - Location Parsing
    
    func parseLocationString(_ locationString: String) -> LocationData? {
        let components = locationString.split(separator: ",")
        
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            return nil
        }
        
        return LocationData(latitude: latitude, longitude: longitude, address: nil)
    }
    
    // MARK: - Event Filtering & Sorting
    
    /// Filter events based on their distance from a location
    func filterEventsByDistance<T>(_ events: [T],
                                 from userLocation: CLLocation,
                                 maxDistance: Double,
                                 locationExtractor: (T) -> LocationData) -> [T] {
        return events.filter { event in
            let locationData = locationExtractor(event)
            let distanceToEvent = distance(from: userLocation, to: locationData)
            return distanceToEvent <= maxDistance
        }
    }
    
    /// Sort events by proximity to a location (closest first)
    func sortEventsByProximity<T>(_ events: [T],
                                to userLocation: CLLocation,
                                locationExtractor: (T) -> LocationData) -> [T] {
        return events.sorted { event1, event2 in
            let location1 = locationExtractor(event1)
            let location2 = locationExtractor(event2)
            
            let distance1 = distance(from: userLocation, to: location1)
            let distance2 = distance(from: userLocation, to: location2)
            
            return distance1 < distance2
        }
    }
    
    /// Get the distance between user location and an event
    func distanceToEvent<T>(_ event: T,
                          from userLocation: CLLocation,
                          locationExtractor: (T) -> LocationData) -> Double {
        let locationData = locationExtractor(event)
        return distance(from: userLocation, to: locationData)
    }
    
    // MARK: - Address Geocoding
    
    /// Convert address to coordinates (placeholder for future implementation)
    func geocode(address: String, completion: @escaping (LocationData?) -> Void) {
        // In a real implementation, you would use CLGeocoder to convert string address to coordinates
        // For now, we'll just call the completion with nil
        completion(nil)
    }
}
