//
//  LocationData.swift
//  GriGriMVP
//
//  Created by Sam Quested on 10/06/2025.
//

import Foundation
import FirebaseFirestore

struct LocationData: Equatable, Hashable, FirestoreCodable {
    let latitude: Double
    let longitude: Double
    let address: String?
    
    // MARK: - Initializer
    init(latitude: Double, longitude: Double, address: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
    
    // MARK: - FirestoreCodable
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        if let address = address {
            data["address"] = address
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let latitude = firestoreData["latitude"] as? Double,
            let longitude = firestoreData["longitude"] as? Double
        else {
            return nil
        }
        
        let address = firestoreData["address"] as? String
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

struct AddressSuggestion: Identifiable, Equatable {
    let id: String
    let displayAddress: String
    let locationData: LocationData
}
