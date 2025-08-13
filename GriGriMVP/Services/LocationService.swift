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
    @Published var cachedLocation: CLLocation?
    @Published var lastLocationUpdate: Date?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // Auto-refresh configuration
    private let autoRefreshInterval: TimeInterval = 300.0 // 5 minutes
    private let cacheValidityDuration: TimeInterval = 600.0 // 10 minutes
    private var autoRefreshTimer: Timer?
    
    // Configuration
    private let locationTimeout: TimeInterval = 30.0
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters
    private let maximumLocationAge: TimeInterval = 300.0
    
    private var isRequestingLocation = false
    
    override init() {
        super.init()
        setupLocationManager()
        
        // Start auto-refresh system
        Task {
            await initializeLocationCache()
            startAutoRefresh()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = 10.0

        authorizationStatus = locationManager.authorizationStatus
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        
        print("Location setup - Services enabled: \(isLocationServicesEnabled), Auth status: \(authorizationStatus.rawValue)")
    }
    
    // MARK: - Cache-Only Public Methods
    
    /// Get cached location - ViewModels should use this
    func getCachedLocation() -> CLLocation? {
        guard let lastUpdate = lastLocationUpdate,
              Date().timeIntervalSince(lastUpdate) < cacheValidityDuration else {
            return nil
        }
        return cachedLocation
    }
    
    /// Check if we have valid cached location
    var hasCachedLocation: Bool {
        return getCachedLocation() != nil
    }
    
    /// Main method ViewModels should call - cache only, no new requests
    func requestCurrentLocation() async throws -> CLLocation {
        guard let cachedLocation = getCachedLocation() else {
            throw LocationError.cacheExpired
        }
        return cachedLocation
    }
    
    /// Manual refresh for pull-to-refresh or explicit user action
    func refreshLocationCache() async throws {
        let location = try await requestLocationInternal()
        cachedLocation = location
        lastLocationUpdate = Date()
    }
    
    // MARK: - Event Filtering & Sorting (Cache-Based)
    
    func filterEventsByDistance<T>(_ events: [T],
                                 maxDistance: Double,
                                 locationExtractor: (T) -> LocationData) throws -> [T] {
        guard let userLocation = getCachedLocation() else {
            throw LocationError.cacheExpired
        }
        
        return events.filter { event in
            let locationData = locationExtractor(event)
            let eventLocation = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
            let distance = userLocation.distance(from: eventLocation)
            return distance <= maxDistance
        }
    }
    
    func sortEventsByProximity<T>(_ events: [T],
                                locationExtractor: (T) -> LocationData) throws -> [T] {
        guard let userLocation = getCachedLocation() else {
            throw LocationError.cacheExpired
        }
        
        return events.sorted { event1, event2 in
            let location1 = locationExtractor(event1)
            let location2 = locationExtractor(event2)
            
            let eventLocation1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
            let eventLocation2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
            
            let distance1 = userLocation.distance(from: eventLocation1)
            let distance2 = userLocation.distance(from: eventLocation2)
            
            return distance1 < distance2
        }
    }
    
    // MARK: - Additional Sorting Methods

    func sortEventsByProximity<T>(_ events: [T],
                                to userLocation: CLLocation,
                                locationExtractor: (T) -> LocationData) -> [T] {
        return events.sorted { event1, event2 in
            let location1 = locationExtractor(event1)
            let location2 = locationExtractor(event2)
            
            let eventLocation1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
            let eventLocation2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
            
            let distance1 = userLocation.distance(from: eventLocation1)
            let distance2 = userLocation.distance(from: eventLocation2)
            
            return distance1 < distance2
        }
    }

    func filterEventsByDistance<T>(_ events: [T],
                                 from userLocation: CLLocation,
                                 maxDistance: Double,
                                 locationExtractor: (T) -> LocationData) -> [T] {
        return events.filter { event in
            let locationData = locationExtractor(event)
            let eventLocation = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
            let distance = userLocation.distance(from: eventLocation)
            return distance <= maxDistance
        }
    }
    
    func distanceToEvent<T>(_ event: T,
                          locationExtractor: (T) -> LocationData) throws -> Double {
        guard let userLocation = getCachedLocation() else {
            throw LocationError.cacheExpired
        }
        
        let locationData = locationExtractor(event)
        let eventLocation = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
        return userLocation.distance(from: eventLocation)
    }
    
    // MARK: - Utility Methods
    
    func distance(from userLocation: CLLocation, to locationData: LocationData) -> Double {
        let eventLocation = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
        return userLocation.distance(from: eventLocation)
    }
    
    func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Geocoding
    
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
                            id: UUID().uuidString,
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
    
    // MARK: - Auto-Refresh System (Private)
    
    private func initializeLocationCache() async {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        do {
            let location = try await requestLocationInternal()
            cachedLocation = location
            lastLocationUpdate = Date()
            print("Location cache initialized: \(location.coordinate)")
        } catch {
            print("Failed to initialize location cache: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func startAutoRefresh() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        stopAutoRefresh()
        
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.autoRefreshLocation()
            }
        }
        
        print("Auto-refresh started - will update location every \(autoRefreshInterval/60) minutes")
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    private func autoRefreshLocation() async {
        guard !isRequestingLocation else { return }
        
        do {
            let location = try await requestLocationInternal()
            cachedLocation = location
            lastLocationUpdate = Date()
            print("Auto-refreshed location: \(location.coordinate)")
        } catch {
            print("Auto-refresh failed: \(error.localizedDescription)")
        }
    }
    
    private func requestLocationInternal() async throws -> CLLocation {
        guard !isRequestingLocation else {
            throw LocationError.requestInProgress
        }
        
        isRequestingLocation = true
        isLoading = true
        
        defer {
            isRequestingLocation = false
            isLoading = false
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            if locationContinuation != nil {
                locationContinuation?.resume(throwing: LocationError.cancelled)
            }
            
            locationContinuation = continuation
            
            guard isLocationServicesEnabled else {
                locationContinuation?.resume(throwing: LocationError.servicesDisabled)
                locationContinuation = nil
                return
            }
            
            guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
                if authorizationStatus == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                    return
                } else {
                    locationContinuation?.resume(throwing: LocationError.permissionDenied)
                    locationContinuation = nil
                    return
                }
            }
            
            locationManager.startUpdatingLocation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + locationTimeout) { [weak self] in
                if let continuation = self?.locationContinuation {
                    self?.locationContinuation = nil
                    continuation.resume(throwing: LocationError.timeout)
                    self?.locationManager.stopUpdatingLocation()
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
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
    
    private func mapLocationError(_ error: Error) -> LocationError {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .permissionDenied
            case .locationUnknown:
                return .unknown("Location unknown")
            case .network:
                return .networkError
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
            
            let locationAge = -location.timestamp.timeIntervalSinceNow
            guard locationAge < maximumLocationAge,
                  location.horizontalAccuracy <= 100.0,
                  location.horizontalAccuracy > 0 else {
                return
            }
            
            isLoading = false
            locationManager.stopUpdatingLocation()
            
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(returning: location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoading = false
            locationManager.stopUpdatingLocation()
            
            let locationError = mapLocationError(error)
            errorMessage = locationError.localizedDescription
            
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(throwing: locationError)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            let previousStatus = authorizationStatus
            authorizationStatus = status
            
            // Only act if the status actually changed
            guard previousStatus != status else { return }
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                startAutoRefresh()
                
                if let continuation = locationContinuation {
                    locationManager.startUpdatingLocation()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + locationTimeout) { [weak self] in
                        if self?.locationContinuation != nil {
                            self?.locationContinuation?.resume(throwing: LocationError.timeout)
                            self?.locationContinuation = nil
                            self?.locationManager.stopUpdatingLocation()
                        }
                    }
                } else if !hasCachedLocation {
                    Task {
                        await self.initializeLocationCache()
                    }
                }
                
            case .denied, .restricted:
                stopAutoRefresh()
                isLoading = false
                errorMessage = LocationError.permissionDenied.localizedDescription
                
                if let continuation = locationContinuation {
                    locationContinuation = nil
                    continuation.resume(throwing: LocationError.permissionDenied)
                }
                
            case .notDetermined:
                stopAutoRefresh()
                break
                
            @unknown default:
                stopAutoRefresh()
                isLoading = false
                let error = LocationError.unknown("Unknown authorization status")
                errorMessage = error.localizedDescription
                
                if let continuation = locationContinuation {
                    locationContinuation = nil
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - LocationError

enum LocationError: Error, LocalizedError {
    case servicesDisabled
    case permissionDenied
    case timeout
    case networkError
    case invalidAddress
    case geocodingFailed
    case reverseGeocodingFailed
    case partialResult
    case cancelled
    case requestInProgress
    case cacheExpired
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "Location services are disabled"
        case .permissionDenied:
            return "Location permission denied"
        case .timeout:
            return "Location request timed out"
        case .networkError:
            return "Network error occurred"
        case .invalidAddress:
            return "Invalid address provided"
        case .geocodingFailed:
            return "Failed to find location"
        case .reverseGeocodingFailed:
            return "Failed to get address"
        case .partialResult:
            return "Partial location result"
        case .cancelled:
            return "Location request cancelled"
        case .requestInProgress:
            return "Location request already in progress"
        case .cacheExpired:
            return "Location data unavailable. Please check your location settings."
        case .unknown(let message):
            return message
        }
    }
}
