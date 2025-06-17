//
//  LocationService.swift
//  GriGriMVP
//
//  Created by Sam Quested on 14/05/2025.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    // Published properties for UI binding
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationServicesEnabled: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
    private var locationTimer: Timer?
    
    // Configuration
    private let locationTimeout: TimeInterval = 30.0
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters
    private let maximumLocationAge: TimeInterval = 300.0 // 5 minutes
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = 10.0
        
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = locationManager.authorizationStatus
    }
    
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
    
    // MARK: - New Location Acquisition Methods
    
    func requestCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            requestCurrentLocation { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func requestCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        guard isLocationServicesEnabled else {
            completion(.failure(LocationError.servicesDisabled))
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            if authorizationStatus == .notDetermined {
                locationCompletion = completion
                locationManager.requestWhenInUseAuthorization()
                return
            } else {
                completion(.failure(LocationError.permissionDenied))
                return
            }
        }
        
        isLoading = true
        errorMessage = nil
        locationCompletion = completion
        
        locationManager.startUpdatingLocation()
        
        // Set timeout timer
        locationTimer = Timer.scheduledTimer(withTimeInterval: locationTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleLocationTimeout()
            }
        }
    }
    
    // Updated geocode method (replacing your placeholder)
    func geocode(address: String) async throws -> LocationData {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            throw LocationError.invalidAddress
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(trimmedAddress) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: self.mapGeocodingError(error))
                } else if let placemark = placemarks?.first,
                          let location = placemark.location {
                    let locationData = LocationData(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        address: self.formatAddress(from: placemark)
                    )
                    continuation.resume(returning: locationData)
                } else {
                    continuation.resume(throwing: LocationError.geocodingFailed)
                }
            }
        }
    }
    
    func reverseGeocode(_ location: CLLocation) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: self.mapGeocodingError(error))
                } else if let placemark = placemarks?.first {
                    let address = self.formatAddress(from: placemark)
                    continuation.resume(returning: address)
                } else {
                    continuation.resume(throwing: LocationError.reverseGeocodingFailed)
                }
            }
        }
    }
    
    func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Address Search & Suggestions
    
    func searchAddresses(_ query: String) async throws -> [AddressSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 3 else {
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(trimmedQuery) { placemarks, error in
                if let error = error {
                    if let clError = error as? CLError, clError.code == .geocodeFoundNoResult {
                        continuation.resume(returning: [])
                    } else {
                        continuation.resume(throwing: self.mapGeocodingError(error))
                    }
                } else if let placemarks = placemarks {
                    let suggestions = placemarks.compactMap { placemark -> AddressSuggestion? in
                        guard let location = placemark.location else { return nil }
                        
                        return AddressSuggestion(
                            id: UUID().uuidString, // Add the missing id parameter
                            displayAddress: self.formatAddress(from: placemark),
                            locationData: LocationData(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude,
                                address: self.formatAddress(from: placemark)
                            )
                        )
                    }
                    continuation.resume(returning: suggestions)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleLocationTimeout() {
        guard isLoading else { return }
        
        locationManager.stopUpdatingLocation()
        isLoading = false
        locationTimer?.invalidate()
        locationTimer = nil
        
        locationCompletion?(.failure(LocationError.timeout))
        locationCompletion = nil
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            components.append(streetNumber)
        }
        if let streetName = placemark.thoroughfare {
            components.append(streetName)
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func mapGeocodingError(_ error: Error) -> LocationError {
        if let clError = error as? CLError {
            switch clError.code {
            case .network:
                return .networkError
            case .geocodeFoundNoResult:
                return .geocodingFailed
            case .geocodeFoundPartialResult:
                return .partialResult
            case .geocodeCanceled:
                return .cancelled
            default:
                return .unknown(clError.localizedDescription)
            }
        }
        return .unknown(error.localizedDescription)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            // Validate location quality
            let locationAge = -location.timestamp.timeIntervalSinceNow
            guard locationAge < maximumLocationAge,
                  location.horizontalAccuracy <= 100.0,
                  location.horizontalAccuracy > 0 else {
                return
            }
            
            isLoading = false
            locationManager.stopUpdatingLocation()
            locationTimer?.invalidate()
            locationTimer = nil
            
            locationCompletion?(.success(location))
            locationCompletion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoading = false
            locationManager.stopUpdatingLocation()
            locationTimer?.invalidate()
            locationTimer = nil
            
            let locationError = mapLocationError(error)
            errorMessage = locationError.localizedDescription
            
            locationCompletion?(.failure(locationError))
            locationCompletion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if let completion = locationCompletion {
                    requestCurrentLocation(completion: completion)
                }
            case .denied, .restricted:
                isLoading = false
                errorMessage = LocationError.permissionDenied.localizedDescription
                locationCompletion?(.failure(LocationError.permissionDenied))
                locationCompletion = nil
            case .notDetermined:
                break
            @unknown default:
                isLoading = false
                let error = LocationError.unknown("Unknown authorization status")
                errorMessage = error.localizedDescription
                locationCompletion?(.failure(error))
                locationCompletion = nil
            }
        }
    }
    
    private func mapLocationError(_ error: Error) -> LocationError {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .permissionDenied
            case .locationUnknown:
                return .locationUnknown
            case .network:
                return .networkError
            default:
                return .unknown(clError.localizedDescription)
            }
        }
        return .unknown(error.localizedDescription)
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case servicesDisabled
    case permissionDenied
    case locationUnknown
    case networkError
    case timeout
    case invalidAddress
    case geocodingFailed
    case reverseGeocodingFailed
    case partialResult
    case cancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .permissionDenied:
            return "Location access denied. Please enable location access in Settings."
        case .locationUnknown:
            return "Unable to determine location. Please try again."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .timeout:
            return "Location request timed out. Please try again."
        case .invalidAddress:
            return "Please enter a valid address."
        case .geocodingFailed:
            return "Could not find location for the provided address."
        case .reverseGeocodingFailed:
            return "Could not determine address for location."
        case .partialResult:
            return "Only partial location results found."
        case .cancelled:
            return "Location request was cancelled."
        case .unknown(let message):
            return message
        }
    }
}
