//
//  GymCreationView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import SwiftUI

struct GymCreationView: View {
    @StateObject private var viewModel = GymCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showProfileImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Image Selection
                    profileImageSelection
                    
                    // Gym Name Input
                    gymNameInput
                    
                    // Address Input
                    addressInput
                    
                    // Divider
                    divider
                    
                    // Facilities Section
                    facilitiesSection
                    
                    // Divider
                    divider
                    
                    // Amenities Section
                    amenitiesSection
                    
                    // Divider
                    divider
                    
                    // Basic Info Section
                    basicInfoSection
                    
                    // Create Button
                    createButton
                }
                .padding()
            }
            .navigationTitle("Create Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(AppTheme.appBackgroundBG)
            .sheet(isPresented: $showProfileImagePicker) {
                ProfileImagePickerView(
                    selectedImage: $viewModel.selectedProfileImage,
                    isPresented: $showProfileImagePicker,
                    onImageConfirmed: viewModel.handleImageSelected
                )
            }
            .sheet(isPresented: $viewModel.showVerificationConfirmation) {
                GymVerificationConfirmationView(gymName: viewModel.createdGymName)
                    .onDisappear {
                        dismiss() // Dismiss the main creation view when confirmation is closed
                    }
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var profileImageSelection: some View {
        VStack(spacing: 8) {
            ProfileImageSelectionButton(
                selectedImage: viewModel.selectedProfileImage,
                isUploading: viewModel.isUploadingImage,
                action: {
                    showProfileImagePicker = true
                }
            )
            
            Text("Tap to add gym profile image")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var gymNameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Gym Name", text: $viewModel.name)
                .font(.appHeadline)
                .foregroundColor(AppTheme.appTextPrimary)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.appContentBG)
                .cornerRadius(12)
        }
    }
    
    private var addressInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            LocationInputView(
                address: $viewModel.address,
                isSearchingAddresses: $viewModel.isSearchingAddresses,
                showAddressSuggestions: $viewModel.showAddressSuggestions,
                addressSuggestions: $viewModel.addressSuggestions,
                isLocationLoading: $viewModel.isLocationLoading,
                useCurrentLocation: $viewModel.useCurrentLocation,
                shouldShowLocationButton: viewModel.shouldShowLocationButton,
                canUseCurrentLocation: viewModel.canUseCurrentLocation,
                locationStatusMessage: viewModel.locationStatusMessage,
                onAddressChange: viewModel.handleManualAddressChange,
                onGetCurrentLocation: viewModel.getCurrentLocation,
                onSelectSuggestion: viewModel.selectAddressSuggestion,
                onRequestLocationPermission: viewModel.requestLocationPermission
            )
        }
    }
    
    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Facilities")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
            HStack(spacing: 36) {
                ForEach(ClimbingTypes.allCases.sortedForDisplay(), id: \.self) { type in
                    VStack(spacing: 8) {
                        Button(action: {
                            viewModel.toggleClimbingType(type)
                        }) {
                            VStack(spacing: 4) {
                                viewModel.climbingTypeIcon(for: type)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(viewModel.isClimbingTypeSelected(type) ? AppTheme.appPrimary : Color.gray.opacity(0.5))
                                
                                Text(viewModel.formatClimbingType(type))
                                    .font(.caption)
                                    .foregroundColor(viewModel.isClimbingTypeSelected(type) ? AppTheme.appTextPrimary : .secondary)
                            }
                        }
                        VStack {
                            if viewModel.isClimbingTypeSelected(type) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                        }
                        .frame(height: 16) // Fixed height to prevent layout shift
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Amenities")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(Amenities.allCases, id: \.self) { amenity in
                    Button(action: {
                        viewModel.toggleAmenity(amenity)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: amenityIcon(for: amenity))
                                .font(.title2)
                                .foregroundColor(viewModel.isAmenitySelected(amenity) ? AppTheme.appPrimary : Color.gray.opacity(0.5))
                            
                            Text(amenity.rawValue)
                                .font(.caption)
                                .foregroundColor(viewModel.isAmenitySelected(amenity) ? AppTheme.appPrimary : Color.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.isAmenitySelected(amenity) ? Color.gray.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Basic Info")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                TextField("Gym Email", text: $viewModel.email)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.appContentBG)
                    .cornerRadius(12)
                
                TextField("Description (Optional)", text: $viewModel.description, axis: .vertical)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .lineLimit(3...6)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.appContentBG)
                    .cornerRadius(12)
            }
        }
    }
    
    private var createButton: some View {
        Button(action: {
            Task {
                await viewModel.createGym()
            }
        }) {
            HStack {
                if viewModel.isLoading || viewModel.isUploadingImage {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }
                
                if viewModel.isUploadingImage {
                    Text("Uploading Image...")
                } else if viewModel.isLoading {
                    Text("Creating Gym...")
                } else {
                    Text("Create Gym")
                }
            }
            .font(.appButtonPrimary)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.isFormValid ? AppTheme.appPrimary : Color.gray)
            .cornerRadius(15)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading || viewModel.isUploadingImage)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(AppTheme.appSecondary)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
    
    // Helper function for amenity icons
    private func amenityIcon(for amenity: Amenities) -> String {
        switch amenity {
        case .showers:
            return "shower.fill"
        case .lockers:
            return "lock.fill"
        case .bar:
            return "wineglass.fill"
        case .food:
            return "fork.knife"
        case .changingRooms:
            return "tshirt.fill"
        case .bathrooms:
            return "toilet.fill"
        case .cafe:
            return "cup.and.saucer.fill"
        case .bikeStorage:
            return "bicycle"
        case .workSpace:
            return "laptopcomputer"
        case .shop:
            return "bag.fill"
        case .wifi:
            return "wifi"
        }
    }
}

#Preview {
    GymCreationView()
}
