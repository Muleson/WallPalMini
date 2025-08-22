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
    @Published var showVerificationConfirmation: Bool = false
    @Published var isLocationLoading: Bool = false
    @Published var createdGymName: String = ""
    
    // Address search - consolidated
    @Published var addressSuggestions: [AddressSuggestion] = []
    @Published var showAddressSuggestions: Bool = false
    @Published var isSearchingAddresses: Bool = false
    
    private let userRepository: UserRepositoryProtocol
    private let gymRepository: GymRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    private let locationService = LocationService.shared
    private var geocodingTask: Task<Void, Never>?
    
    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         mediaRepository: MediaRepositoryProtocol = RepositoryFactory.createMediaRepository()) {
        self.userRepository = userRepository
        self.gymRepository = gymRepository
        self.mediaRepository = mediaRepository
        
        // Observe location service status changes
        observeLocationServiceChanges()
        
        // Initialize location status
        Task { @MainActor in
            checkInitialLocationStatus()
        }
    }
    
    private func observeLocationServiceChanges() {
        // Watch for authorization status changes
        Task { @MainActor in
            // This will reactively update when the location service properties change
            // The @Published properties in LocationService will trigger UI updates
        }
    }
    
    private func checkInitialLocationStatus() {
        // Check if we have a cached location available at startup
        if locationService.hasCachedLocation && canUseCurrentLocation {
            // Location is available but don't auto-fill unless user explicitly requests it
            print("Location cache available for gym creation")
        }
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !selectedClimbingTypes.isEmpty &&
        hasValidLocation
    }
    
    var hasValidLocation: Bool {
        // Either we have a valid address OR we have valid coordinates
        return (!address.isEmpty || (latitude != 0.0 && longitude != 0.0))
    }
    
    var locationPermissionGranted: Bool {
        locationService.authorizationStatus == .authorizedWhenInUse ||
        locationService.authorizationStatus == .authorizedAlways
    }
    
    var canUseCurrentLocation: Bool {
        return locationPermissionGranted && locationService.isLocationServicesEnabled
    }
    
    var shouldShowLocationButton: Bool {
        return locationService.isLocationServicesEnabled
    }
    
    // MARK: - Location Management
    
    func getCurrentLocation() {
        useCurrentLocation = true
        isLocationLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Try to get cached location first
                if let cachedLocation = locationService.getCachedLocation() {
                    await updateLocationData(cachedLocation)
                    await reverseGeocode(location: cachedLocation)
                    return
                }
                
                // If no cached location, try to refresh the cache
                try await locationService.refreshLocationCache()
                
                // Get the newly cached location
                guard let location = locationService.getCachedLocation() else {
                    throw LocationError.cacheExpired
                }
                
                await updateLocationData(location)
                await reverseGeocode(location: location)
                
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isLocationLoading = false
                    self.useCurrentLocation = false
                    
                    if error is LocationError {
                        switch error as! LocationError {
                        case .permissionDenied:
                            self.errorMessage = "Location permission is required. Please enable location access in Settings."
                        case .servicesDisabled:
                            self.errorMessage = "Location services are disabled. Please enable them in Settings."
                        case .cacheExpired:
                            self.errorMessage = "Location data is unavailable. Please check your location settings and try again."
                        case .timeout:
                            self.errorMessage = "Location request timed out. Please try again."
                        case .networkError:
                            self.errorMessage = "Network error while getting location. Please check your connection."
                        default:
                            self.errorMessage = "Failed to get current location: \(error.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = "Failed to get current location: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func updateLocationData(_ location: CLLocation) async {
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.isLocationLoading = false
        }
    }
    
    private func reverseGeocode(location: CLLocation) async {
        do {
            let formattedAddress = try await locationService.reverseGeocode(location)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.address = formattedAddress
            }
        } catch {
            print("Reverse geocoding failed: \(error)")
            // Don't show error to user for reverse geocoding failure
            // The location coordinates are still valid
        }
    }
    
    func requestLocationPermission() {
        if !locationPermissionGranted {
            locationService.openLocationSettings()
        }
    }
    
    var locationStatusMessage: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Location permission not requested"
        case .denied, .restricted:
            return "Location access denied. Tap to open Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            if locationService.hasCachedLocation {
                return "Location available"
            } else {
                return "Getting location..."
            }
        @unknown default:
            return "Unknown location status"
        }
    }
    
    // MARK: - Image Management
    
    func handleImageSelected(_ image: UIImage) {
        selectedProfileImage = image
        // Any additional logic after image selection can be added here
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
    
    // MARK: - Address Search Management
    
    func searchAddresses() {
        // Don't search if we're using current location
        if useCurrentLocation {
            return
        }
        
        // Cancel any existing search
        geocodingTask?.cancel()
        
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedAddress.isEmpty && trimmedAddress.count >= 3 else {
            hideAddressSuggestions()
            return
        }
        
        geocodingTask = Task {
            do {
                // Debounce the search
                try await Task.sleep(nanoseconds: 800_000_000)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isSearchingAddresses = true
                    self.errorMessage = nil
                }
                
                let suggestions = try await locationService.searchAddresses(trimmedAddress)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.addressSuggestions = suggestions
                    self.showAddressSuggestions = !suggestions.isEmpty
                    self.isSearchingAddresses = false
                }
                
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isSearchingAddresses = false
                    self.hideAddressSuggestions()
                    // Don't log cancellation errors
                    if !Task.isCancelled {
                        print("Address search error: \(error)")
                    }
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
    
    func handleManualAddressChange() {
        // Clear current location flag when user manually edits address
        if useCurrentLocation {
            useCurrentLocation = false
        }
        searchAddresses()
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
    
    func validateForm() -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Gym name is required"
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            return "Email is required"
        }
        
        if !trimmedEmail.contains("@") {
            return "Please enter a valid email address"
        }
        
        if selectedClimbingTypes.isEmpty {
            return "Please select at least one climbing facility type"
        }
        
        if !hasValidLocation {
            if !locationPermissionGranted && shouldShowLocationButton {
                return "Please enter an address or enable location access to use your current location"
            } else {
                return "Please enter the gym's address"
            }
        }
        
        return nil
    }
    
    func createGym() async {
        if let validationError = validateForm() {
            errorMessage = validationError
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
                staffUserIds: [],
                verificationStatus: .pending // New gyms start as pending verification
            )
            
            _ = try await gymRepository.createGym(gym)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                self.createdGymName = gym.name
                self.showVerificationConfirmation = true
                self.resetForm()
            }
            
        } catch {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
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
        isLocationLoading = false
        hideAddressSuggestions()
        
        // Cancel any pending geocoding
        geocodingTask?.cancel()
        geocodingTask = nil
    }
    
    func clearLocation() {
        latitude = 0.0
        longitude = 0.0
        address = ""
        useCurrentLocation = false
        errorMessage = nil
    }
    
    func refreshLocationIfNeeded() async {
        // If user is using current location but we don't have cached location, try to refresh
        if useCurrentLocation && !locationService.hasCachedLocation && canUseCurrentLocation {
            do {
                try await locationService.refreshLocationCache()
                if let location = locationService.getCachedLocation() {
                    await updateLocationData(location)
                    await reverseGeocode(location: location)
                }
            } catch {
                print("Failed to refresh location: \(error)")
                // Don't show error to user for background refresh
            }
        }
    }
    
    var locationDisplayText: String {
        if useCurrentLocation && !address.isEmpty {
            return "Current location: \(address)"
        } else if !address.isEmpty {
            return address
        } else if useCurrentLocation {
            return "Getting your current location..."
        } else {
            return ""
        }
    }
    
    deinit {
        geocodingTask?.cancel()
    }
}
