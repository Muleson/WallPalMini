//
//  AddressFormatter.swift
//  GriGriMVP
//
//  Created by Sam Quested on 10/06/2025.
//

import Foundation
import CoreLocation

extension LocationData {
    /// Returns a formatted address string as "Suburb, Town, Country"
    var formattedAddress: String {
        if let address = self.address, !address.isEmpty {
            return AddressFormatter.format(self, style: .suburbCountry)
        } else {
            return "Coordinates: \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))"
        }
    }
    
    /// Returns a short formatted address (Suburb, Town only)
    var shortFormattedAddress: String {
        if let address = self.address, !address.isEmpty {
            return AddressFormatter.format(self, style: .suburbTown)
        } else {
            return "Coordinates: \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))"
        }
    }
    
    /// Returns just the suburb if available
    var suburb: String? {
        guard let address = self.address, !address.isEmpty else { return nil }
        return AddressFormatter.parseAddressComponents(address).first
    }
    
    /// Returns just the town if available
    var town: String? {
        guard let address = self.address, !address.isEmpty else { return nil }
        let components = AddressFormatter.parseAddressComponents(address)
        return components.count >= 2 ? components[1] : nil
    }
    
    /// Returns just the country if available
    var country: String? {
        guard let address = self.address, !address.isEmpty else { return nil }
        return AddressFormatter.parseAddressComponents(address).last
    }
    
    /// Returns formatted address as "Postcode, Town, Country"
    var postcodeFormattedAddress: String {
        if let address = self.address, !address.isEmpty {
            return AddressFormatter.format(self, style: .postcodeToCountry)
        } else {
            return "Coordinates: \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))"
        }
    }
}

struct AddressFormatter {
    enum Style {
        case suburbTownCountry  // "Suburb, Town, Country"
        case suburbTown        // "Suburb, Town"
        case townCountry       // "Town, Country"
        case suburbOnly        // "Suburb"
        case postcodeToCountry  // "Postcode, Town, Country"
        case suburbCountry     // "Suburb, Country" - NEW
        case coordinates       // "Coordinates: lat, lng"
    }
    
    static func format(_ locationData: LocationData, style: Style = .suburbTownCountry) -> String {
        guard let address = locationData.address, !address.isEmpty else {
            return coordinates(for: locationData)
        }
        
        let components = parseAddressComponents(address)
        
        switch style {
        case .suburbTownCountry:
            return formatSuburbTownCountry(components, fallback: address)
        case .suburbTown:
            return formatSuburbTown(components, fallback: address)
        case .townCountry:
            return formatTownCountry(components, fallback: address)
        case .suburbOnly:
            return components.first ?? address
        case .postcodeToCountry:
            return formatPostcodeToCountry(address, components: components, fallback: address)
        case .suburbCountry:
            return formatSuburbCountry(address, components: components, fallback: address)
        case .coordinates:
            return coordinates(for: locationData)
        }
    }
    
    // MARK: Internal Helper Methods (accessible to extension)
    
    static func parseAddressComponents(_ address: String) -> [String] {
        let components = address.components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Filter out postal codes and street numbers for most cases
        // But keep them available for postcode formatting
        return components.filter { component in
            let numericRatio = Double(component.compactMap { $0.isNumber ? 1 : 0 }.reduce(0, +)) / Double(component.count)
            return numericRatio < 0.6 // Less than 60% numbers
        }
    }
    
    static func parseAllAddressComponents(_ address: String) -> [String] {
        // Parse all components including postal codes for postcode formatting
        return address.components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: Private Helper Methods
    
    private static func formatSuburbCountry(_ fullAddress: String, components: [String], fallback: String) -> String {
        let allComponents = parseAllAddressComponents(fullAddress)
        
        // For UK addresses: take suburb (3rd component) and country (last component)
        guard allComponents.count >= 3 else {
            // If less than 3 components, fall back to available components
            if allComponents.count >= 2 {
                return "\(allComponents[0]), \(allComponents.last!)"
            } else if allComponents.count == 1 {
                return allComponents[0]
            } else {
                return fallback
            }
        }
        
        let suburb = allComponents[2]  // 3rd component (index 2)
        let country = allComponents.last!  // Last component
        
        return "\(suburb), \(country)"
    }
    
    private static func formatPostcodeToCountry(_ fullAddress: String, components: [String], fallback: String) -> String {
        let allComponents = parseAllAddressComponents(fullAddress)
        
        // For most address formats, postcode is the second-to-last component
        guard allComponents.count >= 2 else {
            // If less than 2 components, fall back to town, country format
            return formatTownCountry(components, fallback: fallback)
        }
        
        let fullPostcode = allComponents[allComponents.count - 2]  // Second-to-last component
        let shortPostcode = extractShortPostcode(from: fullPostcode)  // Get first part only
        let country = allComponents.last!  // Last component
        
        // Get town from filtered components (excluding postcodes and street numbers)
        let town = components.first ?? "Unknown"
        
        if components.count >= 1 {
            return "\(shortPostcode), \(town), \(country)"
        } else {
            // If no filtered components available, use postcode and country only
            return "\(shortPostcode), \(country)"
        }
    }
    
    private static func extractShortPostcode(from postcode: String) -> String {
        // Split by whitespace and take the first component
        let components = postcode.components(separatedBy: .whitespaces)
        return components.first ?? postcode
    }
    
    private static func formatSuburbTownCountry(_ components: [String], fallback: String) -> String {
        switch components.count {
        case 0:
            return fallback
        case 1:
            return components[0]
        case 2:
            return "\(components[0]), \(components[1])"
        case 3:
            return "\(components[0]), \(components[1]), \(components[2])"
        default:
            // Take first (suburb), middle-ish (town), and last (country)
            let suburb = components[0]
            let town = components[components.count / 2]
            let country = components.last!
            return "\(suburb), \(town), \(country)"
        }
    }
    
    private static func formatSuburbTown(_ components: [String], fallback: String) -> String {
        switch components.count {
        case 0:
            return fallback
        case 1:
            return components[0]
        default:
            return "\(components[0]), \(components[1])"
        }
    }
    
    private static func formatTownCountry(_ components: [String], fallback: String) -> String {
        switch components.count {
        case 0:
            return fallback
        case 1:
            return components[0]
        case 2:
            return "\(components[0]), \(components[1])"
        default:
            // Take second-to-last and last
            return "\(components[components.count - 2]), \(components.last!)"
        }
    }
    
    private static func coordinates(for locationData: LocationData) -> String {
        return "Coordinates: \(String(format: "%.4f", locationData.latitude)), \(String(format: "%.4f", locationData.longitude))"
    }
}
