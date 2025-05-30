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
    private let locationService = LocationService.shared
    private var geocodingTask: Task<Void, Never>?
    
    init() {
        self.userRepository = FirebaseUserRepository()
        self.gymRepository = FirebaseGymRepository()
    }
    
    init(userRepository: UserRepositoryProtocol, gymRepository: GymRepositoryProtocol) {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !selectedClimbingTypes.isEmpty &&
        (!address.isEmpty || (latitude != 0.0 && longitude != 0.0))
    }
    
    var locationPermissionGranted: Bool {
        locationService.authorizationStatus == .authorizedWhenInUse || 
        locationService.authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Location Methods
    
    func getCurrentLocation() {
        errorMessage = nil
        isLocationLoading = true
        
        Task {
            do {
                let location = try await locationService.requestCurrentLocation()
                
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
                self.useCurrentLocation = true
                self.isLocationLoading = false
                
                // Get address for the location
                do {
                    let address = try await locationService.reverseGeocode(location)
                    self.address = address
                } catch {
                    // Don't fail the whole operation if reverse geocoding fails
                    print("Failed to get address: \(error)")
                }
                
            } catch {
                self.isLocationLoading = false
                if let locationError = error as? LocationError {
                    self.errorMessage = locationError.localizedDescription
                } else {
                    self.errorMessage = "Failed to get location: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func geocodeAddress() {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else { return }
        
        // Cancel any pending geocoding
        geocodingTask?.cancel()
        
        geocodingTask = Task {
            // Debounce the geocoding request
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.isLocationLoading = true
            }
            
            do {
                let locationData = try await locationService.geocode(address: trimmedAddress)
                
                await MainActor.run {
                    self.latitude = locationData.latitude
                    self.longitude = locationData.longitude
                    self.useCurrentLocation = false
                    self.isLocationLoading = false
                    self.errorMessage = nil
                }
                
            } catch {
                await MainActor.run {
                    self.isLocationLoading = false
                    if let locationError = error as? LocationError {
                        self.errorMessage = locationError.localizedDescription
                    } else {
                        self.errorMessage = "Failed to find location: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func openLocationSettings() {
        locationService.openLocationSettings()
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
                profileImage: nil,
                createdAt: Date(),
                ownerId: currentUserId,
                staffUserIds: []
            )
            
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
        
        // Cancel any pending geocoding
        geocodingTask?.cancel()
        geocodingTask = nil
    }
    
    deinit {
        geocodingTask?.cancel()
    }
}
