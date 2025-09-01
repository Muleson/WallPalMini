//
//  GymManagementViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import Foundation
import SwiftUI

/*
// COMMENTED OUT FOR TESTING - Sam 2025-08-23
@MainActor
class GymManagementViewModel: ObservableObject {
    @Published var gyms: [Gym] = []
    @Published var userPermissions: [GymPermission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let permissionRepository: PermissionRepositoryProtocol
    
    init(gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         permissionRepository: PermissionRepositoryProtocol = RepositoryFactory.createPermissionRepository()) {
        self.gymRepository = gymRepository
        self.userRepository = userRepository
        self.permissionRepository = permissionRepository
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
            
            // Step 1: Get all permissions for the current user
            userPermissions = try await permissionRepository.getPermissionsForUser(userId: currentUserId)
            print("DEBUG: User has \(userPermissions.count) gym permissions")
            
            // Step 2: Extract gym IDs from permissions
            let gymIds = userPermissions.map { $0.gymId }
            
            // Step 3: Batch fetch only the gyms the user has access to
            if !gymIds.isEmpty {
                let managedGyms = try await gymRepository.getGyms(ids: gymIds)
                gyms = managedGyms.sorted { $0.createdAt > $1.createdAt } // Most recent first
                print("DEBUG: Loaded \(gyms.count) gyms")
            } else {
                gyms = []
                print("DEBUG: User has no gym permissions")
            }
            
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
            // Check if user has owner permission
            guard let permission = userPermissions.first(where: { $0.gymId == gym.id }),
                  permission.role == .owner else {
                errorMessage = "Only the gym owner can delete this gym"
                return
            }
            
            // Delete the gym (this will also delete all permissions in the repository)
            try await gymRepository.deleteGym(id: gym.id)
            
            // Remove from local arrays
            gyms.removeAll { $0.id == gym.id }
            userPermissions.removeAll { $0.gymId == gym.id }
            
        } catch {
            errorMessage = "Failed to delete gym: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Permission Helpers (Updated)
    
    func getUserPermissionForGym(_ gym: Gym) -> GymPermission? {
        return userPermissions.first { $0.gymId == gym.id }
    }
    
    func canUserDeleteGym(_ gym: Gym) -> Bool {
        guard let permission = getUserPermissionForGym(gym) else { return false }
        return permission.role.canDeleteGym && permission.isValid
    }
    
    func canUserManageStaff(_ gym: Gym) -> Bool {
        guard let permission = getUserPermissionForGym(gym) else { return false }
        return permission.role.canManageStaff && permission.isValid
    }
    
    func canUserCreateEvents(_ gym: Gym) -> Bool {
        guard let permission = getUserPermissionForGym(gym) else { return false }
        return permission.role.canCreateEvents && permission.isValid
    }
    
    func getUserRoleForGym(_ gym: Gym) -> String {
        guard let permission = getUserPermissionForGym(gym) else { return "Member" }
        return permission.role.displayName
    }
    
    // MARK: - Gym Statistics (Updated)
    
    func getStaffCount(for gym: Gym) async -> Int {
        do {
            let permissions = try await permissionRepository.getPermissionsForGym(gymId: gym.id)
            return permissions.filter { $0.role == .staff }.count
        } catch {
            print("Failed to get staff count: \(error)")
            return 0
        }
    }
    
    func getEventCount(for gym: Gym) -> Int {
        return gym.events.count
    }
    
    func getGymSummary(for gym: Gym) -> String {
        let eventCount = getEventCount(for: gym)
        
        var components: [String] = []
        
        // Note: Staff count would need to be loaded asynchronously
        // For now, just show events
        if eventCount > 0 {
            components.append("\(eventCount) events")
        }
        
        return components.isEmpty ? "No activity" : components.joined(separator: " • ")
    }
    
    // MARK: - Search and Filtering (Updated)
    
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
        let ownerPermissions = userPermissions.filter { $0.role == .owner }
        let ownerGymIds = Set(ownerPermissions.map { $0.gymId })
        return gyms.filter { ownerGymIds.contains($0.id) }
    }
    
    func getStaffGyms() -> [Gym] {
        let staffPermissions = userPermissions.filter { $0.role == .staff }
        let staffGymIds = Set(staffPermissions.map { $0.gymId })
        return gyms.filter { staffGymIds.contains($0.id) }
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
    
    // Edit mode state
    @Published var isEditingProfile = false
    @Published var hasUnsavedChanges = false
    @Published var showSuccessAlert = false
    
    // Climbing types and amenities editing state
    @Published var isEditingClimbingTypes = false
    @Published var isEditingAmenities = false
    
    // Editable properties (REMOVED location-related properties)
    @Published var editedName: String = ""
    @Published var editedEmail: String = ""
    @Published var editedDescription: String = ""
    @Published var editedClimbingTypes: Set<ClimbingTypes> = []
    @Published var editedAmenities: Set<Amenities> = []
    
    // Image editing
    @Published var selectedProfileImage: UIImage?
    @Published var isUploadingImage = false
    @Published var hasImageChanged = false
    
    // REMOVED: Address search functionality
    // REMOVED: Location service
    // REMOVED: Geocoding task
    
    private let gymRepository: GymRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    init(gym: Gym,
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         mediaRepository: MediaRepositoryProtocol = RepositoryFactory.createMediaRepository(),
         permissionRepository: PermissionRepositoryProtocol = RepositoryFactory.createPermissionRepository()) {
        self.gym = gym
        self.gymRepository = gymRepository
        self.userRepository = userRepository
        self.mediaRepository = mediaRepository
        self.permissionRepository = permissionRepository
        
        // Initialize edited values with current gym data
        initializeEditedValues()
        
        // Load user's permission for this gym
        Task {
            await loadUserPermission()
        }
    }
    
    // MARK: - Initialization
    
    private func initializeEditedValues() {
        editedName = gym.name
        editedEmail = gym.email
        editedDescription = gym.description ?? ""
        editedClimbingTypes = Set(gym.climbingType)
        editedAmenities = Set(gym.amenities)
        // REMOVED: Location initialization
    }
    
    // MARK: - User Permission Logic (Updated for new permission system)
    
    @Published var userPermission: GymPermission?
    private let permissionRepository: PermissionRepositoryProtocol
    
    var currentUserId: String? {
        userRepository.getCurrentAuthUser()
    }
    
    var canManageStaff: Bool {
        guard let permission = userPermission else { return false }
        return permission.role.canManageStaff && permission.isValid
    }
    
    var canManageEvents: Bool {
        guard let permission = userPermission else { return false }
        return permission.role.canCreateEvents && permission.isValid
    }
    
    var canEditGym: Bool {
        guard let permission = userPermission else { return false }
        return permission.role.canEditGymDetails && permission.isValid
    }
    
    var userRole: String {
        guard let permission = userPermission else { return "Member" }
        return permission.role.displayName
    }
    
    // Load user's permission for this gym
    func loadUserPermission() async {
        guard let userId = currentUserId else { return }
        
        do {
            userPermission = try await permissionRepository.getPermission(userId: userId, gymId: gym.id)
        } catch {
            print("Failed to load user permission: \(error)")
            userPermission = nil
        }
    }
    
    // MARK: - Validation (SIMPLIFIED)
    
    var isFormValid: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editedEmail.contains("@") &&
        !editedClimbingTypes.isEmpty
        // REMOVED: Location validation
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
            
            // REMOVED: Location update logic
            // Keep the original location unchanged
            
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
                    ownerId: "gym_\(gym.id)",
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
    
    // MARK: - Image Management
    
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
        if isEditingAmenities {
            return editedAmenities.contains(amenity)
        } else {
            return gym.amenities.contains(amenity)
        }
    }
    
    // MARK: - Formatting Logic (READ-ONLY for location)
    
    var formattedAddress: String {
        return gym.location.formattedAddress
    }
    
    var formattedCreatedDate: String {
        gym.createdAt.formatted(date: .abbreviated, time: .omitted)
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
    
    // MARK: - Edit Mode Management for Sections
    
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
}
*/
// END COMMENTED OUT FOR TESTING - Sam 2025-08-23
