//
//  GymManagementViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import Foundation
import SwiftUI

@MainActor
class GymManagementViewModel: ObservableObject {
    @Published var gyms: [Gym] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository()) {
        self.gymRepository = gymRepository
        self.userRepository = userRepository
    }
    
    func loadGyms() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user ID
            guard let currentUserId = userRepository.getCurrentAuthUser() else {
                print("DEBUG: No current user ID found")
                errorMessage = "You must be logged in to manage gyms"
                isLoading = false
                return
            }
            
            print("DEBUG: Loading gyms for user ID: \(currentUserId)")
            
            // Load only gyms that the current user can manage (owner or staff)
            let managedGyms = try await gymRepository.getGymsUserCanManage(userId: currentUserId)
            print("DEBUG: Repository returned \(managedGyms.count) gyms")
            
            gyms = managedGyms.sorted { $0.createdAt > $1.createdAt } // Most recent first
            print("DEBUG: View model now has \(gyms.count) gyms")
            
        } catch {
            print("DEBUG: Error loading gyms: \(error)")
            errorMessage = "Failed to load gyms: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteGym(_ gym: Gym) async {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            errorMessage = "You must be logged in to delete gyms"
            return
        }
        
        do {
            // Only owners can delete gyms
            guard gym.isOwner(userId: currentUserId) else {
                errorMessage = "Only the gym owner can delete this gym"
                return
            }
            
            // Delete the gym
            try await gymRepository.deleteGym(id: gym.id)
            
            // Remove from local array
            gyms.removeAll { $0.id == gym.id }
            
        } catch {
            errorMessage = "Failed to delete gym: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Permission Helpers
    
    func canUserDeleteGym(_ gym: Gym) -> Bool {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return false
        }
        
        // Only owners can delete gyms
        return gym.isOwner(userId: currentUserId)
    }
    
    func canUserManageStaff(_ gym: Gym) -> Bool {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return false
        }
        
        // Only owners can manage staff
        return gym.canAddStaff(userId: currentUserId)
    }
    
    func canUserCreateEvents(_ gym: Gym) -> Bool {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return false
        }
        
        // Both owners and staff can create events
        return gym.canCreateEvents(userId: currentUserId)
    }
    
    func getUserRoleForGym(_ gym: Gym) -> String {
        guard let currentUserId = userRepository.getCurrentAuthUser() else {
            return "Unknown"
        }
        
        if gym.isOwner(userId: currentUserId) {
            return "Owner"
        } else if gym.isStaff(userId: currentUserId) {
            return "Staff"
        } else {
            return "Member"
        }
    }
    
    // MARK: - Gym Statistics
    
    func getStaffCount(for gym: Gym) -> Int {
        return gym.staffUserIds.count
    }
    
    func getEventCount(for gym: Gym) -> Int {
        return gym.events.count
    }
    
    func getGymSummary(for gym: Gym) -> String {
        let staffCount = getStaffCount(for: gym)
        let eventCount = getEventCount(for: gym)
        
        var components: [String] = []
        
        if staffCount > 0 {
            components.append("\(staffCount) staff")
        }
        
        if eventCount > 0 {
            components.append("\(eventCount) events")
        }
        
        return components.isEmpty ? "No activity" : components.joined(separator: " • ")
    }
    
    // MARK: - Search and Filtering
    
    func filterGyms(by searchText: String) -> [Gym] {
        guard !searchText.isEmpty else { return gyms }
        
        let lowercaseSearch = searchText.lowercased()
        
        return gyms.filter { gym in
            gym.name.lowercased().contains(lowercaseSearch) ||
            gym.email.lowercased().contains(lowercaseSearch) ||
            gym.location.address?.lowercased().contains(lowercaseSearch) == true ||
            gym.description?.lowercased().contains(lowercaseSearch) == true
        }
    }
    
    func getOwnedGyms() -> [Gym] {
        guard let currentUserId = userRepository.getCurrentAuthUser() else { return [] }
        
        return gyms.filter { gym in
            gym.isOwner(userId: currentUserId)
        }
    }
    
    func getStaffGyms() -> [Gym] {
        guard let currentUserId = userRepository.getCurrentAuthUser() else { return [] }
        
        return gyms.filter { gym in
            gym.isStaff(userId: currentUserId) && !gym.isOwner(userId: currentUserId)
        }
    }
    
    // MARK: - Data Refresh
    
    func refreshGym(_ gym: Gym) async {
        do {
            if let updatedGym = try await gymRepository.getGym(id: gym.id) {
                // Update the gym in our local array
                if let index = gyms.firstIndex(where: { $0.id == gym.id }) {
                    gyms[index] = updatedGym
                }
            }
        } catch {
            errorMessage = "Failed to refresh gym data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Bulk Operations
    
    func refreshAllGyms() async {
        await loadGyms()
    }
}

@MainActor
class GymDetailManagementViewModel: ObservableObject {
    @Published var gym: Gym
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Replace isEditing with more specific property
    @Published var isEditingProfile = false
    @Published var hasUnsavedChanges = false
    @Published var showSuccessAlert = false
    
    // Climbing types and amenities editing state
    @Published var isEditingClimbingTypes = false
    @Published var isEditingAmenities = false

    
    // Editable properties - mirror GymCreationViewModel
    @Published var editedName: String = ""
    @Published var editedEmail: String = ""
    @Published var editedDescription: String = ""
    @Published var editedAddress: String = ""
    @Published var editedLatitude: Double = 0.0
    @Published var editedLongitude: Double = 0.0
    @Published var editedClimbingTypes: Set<ClimbingTypes> = []
    @Published var editedAmenities: Set<Amenities> = []
    
    // Image editing
    @Published var selectedProfileImage: UIImage?
    @Published var isUploadingImage = false
    @Published var hasImageChanged = false
    
    // Address search functionality
    @Published var addressSuggestions: [AddressSuggestion] = []
    @Published var showAddressSuggestions = false
    @Published var isSearchingAddresses = false
    
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    private let locationService = LocationService.shared
    private var geocodingTask: Task<Void, Never>?
    
    init(gym: Gym,
         gymRepository: GymRepositoryProtocol = FirebaseGymRepository(),
         userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         mediaRepository: MediaRepositoryProtocol = FirebaseMediaRepository()) {
        self.gym = gym
        self.gymRepository = gymRepository
        self.userRepository = userRepository
        self.mediaRepository = mediaRepository
        
        // Initialize edited values with current gym data
        initializeEditedValues()
    }
    
    // MARK: - Initialization
    
    private func initializeEditedValues() {
        editedName = gym.name
        editedEmail = gym.email
        editedDescription = gym.description ?? ""
        editedAddress = gym.location.address ?? ""
        editedLatitude = gym.location.latitude
        editedLongitude = gym.location.longitude
        editedClimbingTypes = Set(gym.climbingType)
        editedAmenities = Set(gym.amenities)
    }
    
    // MARK: - User Permission Logic
    
    var currentUserId: String? {
        userRepository.getCurrentAuthUser()
    }
    
    var canManageStaff: Bool {
        guard let userId = currentUserId else { return false }
        return gym.canAddStaff(userId: userId)
    }
    
    var canManageEvents: Bool {
        guard let userId = currentUserId else { return false }
        return gym.canCreateEvents(userId: userId)
    }
    
    var canEditGym: Bool {
        guard let userId = currentUserId else { return false }
        return gym.isOwner(userId: userId) // Only owners can edit gym details
    }
    
    var userRole: String {
        guard let userId = currentUserId else { return "Unknown" }
        
        if gym.isOwner(userId: userId) {
            return "Owner"
        } else if gym.isStaff(userId: userId) {
            return "Staff"
        } else {
            return "Member"
        }
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editedEmail.contains("@") &&
        !editedClimbingTypes.isEmpty &&
        (!editedAddress.isEmpty || (editedLatitude != 0.0 && editedLongitude != 0.0))
    }
    
    var locationPermissionGranted: Bool {
        locationService.authorizationStatus == .authorizedWhenInUse ||
        locationService.authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Edit Mode Management
    
    func enterProfileEditMode() {
        isEditingProfile = true
        initializeEditedValues() // Reset to current values
        hasUnsavedChanges = false
        hasImageChanged = false
        selectedProfileImage = nil
    }
    
    func cancelProfileEditing() {
        isEditingProfile = false
        isEditingClimbingTypes = false
        isEditingAmenities = false
        hasUnsavedChanges = false
        hasImageChanged = false
        selectedProfileImage = nil
        hideAddressSuggestions()
        geocodingTask?.cancel()
        initializeEditedValues() // Reset to original values
    }
    
    func saveChanges() async {
        guard isFormValid && canEditGym else {
            errorMessage = "Invalid form data or insufficient permissions"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedGym = gym
            
            // Update basic info
            updatedGym.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedGym.email = editedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedGym.description = editedDescription.isEmpty ? nil : editedDescription
            updatedGym.climbingType = Array(editedClimbingTypes)
            updatedGym.amenities = Array(editedAmenities)
            
            // Update location
            let locationData = LocationData(
                latitude: editedLatitude,
                longitude: editedLongitude,
                address: editedAddress.isEmpty ? nil : editedAddress
            )
            updatedGym.location = locationData
            
            // Handle profile image update
            if hasImageChanged, let profileImage = selectedProfileImage {
                isUploadingImage = true
                
                // Delete old image if it exists
                if let oldImage = gym.profileImage {
                    try? await mediaRepository.deleteMedia(oldImage)
                }
                
                // Upload new image
                let newImageMedia = try await mediaRepository.uploadImage(
                    profileImage,
                    ownerId: gym.ownerId,
                    compressionQuality: 0.8
                )
                updatedGym.profileImage = newImageMedia
                isUploadingImage = false
            }
            
            // Save to repository
            try await gymRepository.updateGym(updatedGym)
            
            // Update local state
            self.gym = updatedGym
            self.isEditingProfile = false
            self.hasUnsavedChanges = false
            self.hasImageChanged = false
            self.selectedProfileImage = nil
            self.showSuccessAlert = true
            
        } catch {
            isUploadingImage = false
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Image Management - Simplified
    
    func handleImageSelected(_ image: UIImage) {
        selectedProfileImage = image
        hasImageChanged = true
        hasUnsavedChanges = true
    }
    
    // MARK: - Climbing Types Management
    
    func toggleClimbingType(_ type: ClimbingTypes) {
        if editedClimbingTypes.contains(type) {
            editedClimbingTypes.remove(type)
        } else {
            editedClimbingTypes.insert(type)
        }
        hasUnsavedChanges = true
    }
    
    func isClimbingTypeSelected(_ type: ClimbingTypes) -> Bool {
        editedClimbingTypes.contains(type)
    }
    
    // MARK: - Amenities Management
    
    func toggleAmenity(_ amenity: Amenities) {
        if editedAmenities.contains(amenity) {
            editedAmenities.remove(amenity)
        } else {
            editedAmenities.insert(amenity)
        }
        hasUnsavedChanges = true
    }
    
    func isAmenitySelected(_ amenity: Amenities) -> Bool {
        // Fix: Check the correct editing state
        if isEditingAmenities {
            return editedAmenities.contains(amenity)
        } else {
            return gym.amenities.contains(amenity)
        }
    }
    
    // MARK: - Location Methods
    
    func getCurrentLocation() {
        errorMessage = nil
        hideAddressSuggestions()
        
        Task {
            do {
                let location = try await locationService.requestCurrentLocation()
                
                self.editedLatitude = location.coordinate.latitude
                self.editedLongitude = location.coordinate.longitude
                self.hasUnsavedChanges = true
                
                // Get address for the location
                do {
                    let address = try await locationService.reverseGeocode(location)
                    self.editedAddress = address
                } catch {
                    print("Failed to get address: \(error)")
                }
                
            } catch {
                if let locationError = error as? LocationError {
                    self.errorMessage = locationError.localizedDescription
                } else {
                    self.errorMessage = "Failed to get location: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func searchAddresses() {
        let trimmedAddress = editedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        editedAddress = suggestion.displayAddress
        editedLatitude = suggestion.locationData.latitude
        editedLongitude = suggestion.locationData.longitude
        hasUnsavedChanges = true
        hideAddressSuggestions()
    }
    
    private func hideAddressSuggestions() {
        showAddressSuggestions = false
        addressSuggestions = []
    }
    
    // MARK: - Formatting Logic
    
    var formattedAddress: String {
        return gym.location.formattedAddress
    }
    
    var formattedCreatedDate: String {
        gym.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
    
    func formatClimbingType(_ type: ClimbingTypes) -> String {
        switch type {
        case .bouldering: return "Boulder"
        case .sport: return "Sport"
        case .board: return "Board"
        case .gym: return "Gym"
        }
    }
    
    func climbingTypeIcon(for type: ClimbingTypes) -> Image {
        switch type {
        case .bouldering: return AppIcons.boulder
        case .sport: return AppIcons.sport
        case .board: return AppIcons.board
        case .gym: return AppIcons.gym
        }
    }
    
    // MARK: - Data Management
    
    func refreshGym() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let updatedGym = try await gymRepository.getGym(id: gym.id) {
                self.gym = updatedGym
                if !isEditingProfile {
                    initializeEditedValues() // Update edited values if not currently editing
                }
            }
        } catch {
            errorMessage = "Failed to refresh gym: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Climbing Types and Amenities Edit Mode
    
    func enterClimbingTypesEditMode() {
        isEditingClimbingTypes = true
        hasUnsavedChanges = false
    }
    
    func enterAmenitiesEditMode() {
        isEditingAmenities = true
        hasUnsavedChanges = false
    }
    
    func cancelClimbingTypesEditing() {
        isEditingClimbingTypes = false
        hasUnsavedChanges = false
        initializeEditedValues() // Reset climbing types
    }
    
    func cancelAmenitiesEditing() {
        isEditingAmenities = false
        hasUnsavedChanges = false
        initializeEditedValues() // Reset amenities
    }
    
    deinit {
        geocodingTask?.cancel()
    }
}
