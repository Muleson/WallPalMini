//
//  GymCreationViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import Foundation
import CoreLocation
import SwiftUI
import UIKit

@MainActor
class GymCreationViewModel: ObservableObject {
    // Basic gym information
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var description: String = ""
    @Published var address: String = ""
    
    // Profile image
    @Published var selectedProfileImage: UIImage?
    @Published var isUploadingImage: Bool = false
    
    // Location data
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var useCurrentLocation: Bool = false
    
    // Climbing types
    @Published var selectedClimbingTypes: Set<ClimbingTypes> = []
    
    // Amenities
    @Published var selectedAmenities: Set<Amenities> = []
    
    // State management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert: Bool = false
    @Published var isLocationLoading: Bool = false
    
    // Address search - consolidated
    @Published var addressSuggestions: [AddressSuggestion] = []
    @Published var showAddressSuggestions: Bool = false
    @Published var isSearchingAddresses: Bool = false
    
    private let userRepository: UserRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    private let locationService = LocationService.shared
    private var geocodingTask: Task<Void, Never>?
    
    init() {
        self.userRepository = RepositoryFactory.createUserRepository()
        self.gymRepository = RepositoryFactory.createGymRepository()
        self.mediaRepository = RepositoryFactory.createMediaRepository()
    }
    
    init(userRepository: UserRepositoryProtocol, gymRepository: GymRepositoryProtocol, mediaRepository: MediaRepositoryProtocol) {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        self.mediaRepository = mediaRepository
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
    
    // MARK: - Image Management - Simplified
    
    func handleImageSelected(_ image: UIImage) {
        selectedProfileImage = image
    }
    
    // MARK: - Climbing Types Management
    
    func toggleClimbingType(_ type: ClimbingTypes) {
        if selectedClimbingTypes.contains(type) {
            selectedClimbingTypes.remove(type)
        } else {
            selectedClimbingTypes.insert(type)
        }
    }
    
    func isClimbingTypeSelected(_ type: ClimbingTypes) -> Bool {
        selectedClimbingTypes.contains(type)
    }
    
    func climbingTypeIcon(for type: ClimbingTypes) -> Image {
        switch type {
        case .bouldering:
            return AppIcons.boulder
        case .sport:
            return AppIcons.sport
        case .board:
            return AppIcons.board
        case .gym:
            return AppIcons.gym
        }
    }
    
    func formatClimbingType(_ type: ClimbingTypes) -> String {
        switch type {
        case .bouldering:
            return "Boulder"
        case .sport:
            return "Sport"
        case .board:
            return "Board"
        case .gym:
            return "Gym"
        }
    }
    
    // MARK: - Location Methods
    
    func getCurrentLocation() {
        errorMessage = nil
        isLocationLoading = true
        hideAddressSuggestions()
        
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
    
    func searchAddresses() {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedAddress.count >= 3 else {
            hideAddressSuggestions()
            return
        }
        
        geocodingTask?.cancel()
        
        geocodingTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.isSearchingAddresses = true
                self.errorMessage = nil
            }
            
            do {
                let suggestions = try await locationService.searchAddresses(trimmedAddress)
                
                await MainActor.run {
                    self.addressSuggestions = suggestions
                    self.showAddressSuggestions = !suggestions.isEmpty
                    self.isSearchingAddresses = false
                }
                
            } catch {
                await MainActor.run {
                    self.isSearchingAddresses = false
                    self.hideAddressSuggestions()
                    print("Address search error: \(error)")
                }
            }
        }
    }
    
    func selectAddressSuggestion(_ suggestion: AddressSuggestion) {
        address = suggestion.displayAddress
        latitude = suggestion.locationData.latitude
        longitude = suggestion.locationData.longitude
        useCurrentLocation = false
        hideAddressSuggestions()
    }
    
    private func hideAddressSuggestions() {
        showAddressSuggestions = false
        addressSuggestions = []
    }
    
    // MARK: - Amenities Management
    
    func toggleAmenity(_ amenity: Amenities) {
        if selectedAmenities.contains(amenity) {
            selectedAmenities.remove(amenity)
        } else {
            selectedAmenities.insert(amenity)
        }
    }
    
    func isAmenitySelected(_ amenity: Amenities) -> Bool {
        selectedAmenities.contains(amenity)
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
            
            // Upload profile image if selected
            var profileImageMedia: MediaItem?
            if let profileImage = selectedProfileImage {
                isUploadingImage = true
                do {
                    profileImageMedia = try await mediaRepository.uploadImage(
                        profileImage,
                        ownerId: currentUserId,
                        compressionQuality: 0.8
                    )
                } catch {
                    isUploadingImage = false
                    self.errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                isUploadingImage = false
            }
            
            let gym = Gym(
                id: UUID().uuidString,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                location: locationData,
                climbingType: Array(selectedClimbingTypes),
                amenities: Array(selectedAmenities),
                events: [],
                profileImage: profileImageMedia,
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
        selectedAmenities.removeAll()
        selectedProfileImage = nil
        errorMessage = nil
        hideAddressSuggestions()
        
        // Cancel any pending geocoding
        geocodingTask?.cancel()
        geocodingTask = nil
    }
    
    deinit {
        geocodingTask?.cancel()
    }
}
