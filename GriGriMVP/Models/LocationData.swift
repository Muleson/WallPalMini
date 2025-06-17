//
//  LocationData.swift
//  GriGriMVP
//
//  Created by Sam Quested on 10/06/2025.
//

import Foundation

struct LocationData: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
    let address: String?
}

struct AddressSuggestion: Identifiable, Equatable {
    let id: String
    let displayAddress: String
    let locationData: LocationData
}
