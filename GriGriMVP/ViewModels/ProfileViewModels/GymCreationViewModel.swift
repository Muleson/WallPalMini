//
//  GymCreationViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class GymCreationViewModel: ObservableObject {
    // Basic gym information
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var description: String = ""
    @Published var address: String = ""
    
    // Location data
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var useCurrentLocation: Bool = false
    
    // Climbing types
    @Published var selectedClimbingTypes: Set<ClimbingTypes> = []
    
    // Amenities
    @Published var amenities: [String] = []
    @Published var newAmenity: String = ""
    
    // State management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert: Bool = false
    @Published var isLocationLoading: Bool = false
    
    private let userRepository: UserRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    private let locationManager = CLLocationManager()
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         gymRepository: GymRepositoryProtocol = FirebaseGymRepository())
    {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !selectedClimbingTypes.isEmpty &&
        (!address.isEmpty || (latitude != 0.0 && longitude != 0.0))
    }
    
    // MARK: - Location Methods
    
    func getCurrentLocation() {
        isLocationLoading = true
        errorMessage = nil
        
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are not enabled"
            isLocationLoading = false
            return
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = locationManager.location {
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                useCurrentLocation = true
                isLocationLoading = false
                
                // Reverse geocode to get address
                reverseGeocodeLocation(location)
            } else {
                errorMessage = "Unable to get current location"
                isLocationLoading = false
            }
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable in Settings."
            isLocationLoading = false
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            isLocationLoading = false
        @unknown default:
            errorMessage = "Unknown location authorization status"
            isLocationLoading = false
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to get address: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    if let postalCode = placemark.postalCode {
                        addressComponents.append(postalCode)
                    }
                    
                    self?.address = addressComponents.joined(separator: ", ")
                }
            }
        }
    }
    
    func geocodeAddress() {
        guard !address.isEmpty else { return }
        
        isLocationLoading = true
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLocationLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to find location: \(error.localizedDescription)"
                    return
                }
                
                if let location = placemarks?.first?.location {
                    self?.latitude = location.coordinate.latitude
                    self?.longitude = location.coordinate.longitude
                    self?.useCurrentLocation = false
                }
            }
        }
    }
    
    // MARK: - Amenities Management
    
    func addAmenity() {
        let trimmed = newAmenity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !amenities.contains(trimmed) else { return }
        
        amenities.append(trimmed)
        newAmenity = ""
    }
    
    func removeAmenity(_ amenity: String) {
        amenities.removeAll { $0 == amenity }
    }
    
    // MARK: - Gym Creation
    
    func createGym() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let locationData = LocationData(
                latitude: latitude,
                longitude: longitude,
                address: address.isEmpty ? nil : address
            )
            
            // Get the current user ID - replace with your actual authentication code
            guard let currentUserId = userRepository.getCurrentAuthUser() else {
                throw NSError(domain: "GymCreation", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to create a gym"])
            }
            
            let gym = Gym(
                id: UUID().uuidString,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                location: locationData,
                climbingType: Array(selectedClimbingTypes),
                amenities: amenities,
                events: [],
                imageUrl: nil,
                createdAt: Date(),
                ownerId: currentUserId,
                staffUserIds: []
            )
            
            // Actually call the repository to create the gym
            _ = try await gymRepository.createGym(gym)
            
            await MainActor.run {
                self.isLoading = false
                self.showSuccessAlert = true
                self.resetForm()
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to create gym: \(error.localizedDescription)"
            }
        }
    }
    
    func resetForm() {
        name = ""
        email = ""
        description = ""
        address = ""
        latitude = 0.0
        longitude = 0.0
        useCurrentLocation = false
        selectedClimbingTypes.removeAll()
        amenities.removeAll()
        newAmenity = ""
        errorMessage = nil
    }
}
