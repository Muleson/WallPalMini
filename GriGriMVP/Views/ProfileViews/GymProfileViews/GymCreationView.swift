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
                VStack(spacing: 24) {
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
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Gym created successfully!")
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
            HStack {
                TextField("Gym Address", text: $viewModel.address)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .onChange(of: viewModel.address) { _ in
                        viewModel.searchAddresses()
                    }
                
                if viewModel.isSearchingAddresses {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                if viewModel.locationPermissionGranted {
                    Button(action: viewModel.getCurrentLocation) {
                        Image(systemName: "location")
                            .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.appContentBG)
            .cornerRadius(12)
            
            // Address suggestions dropdown
            if viewModel.showAddressSuggestions {
                VStack(spacing: 0) {
                    ForEach(viewModel.addressSuggestions) { suggestion in
                        Button(action: {
                            viewModel.selectAddressSuggestion(suggestion)
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Text(suggestion.displayAddress)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion.id != viewModel.addressSuggestions.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(AppTheme.appContentBG)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
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
                ForEach(ClimbingTypes.allCases, id: \.self) { type in
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
                        
                        // Fixed height container for checkmark to prevent layout shift
                        VStack {
                            if viewModel.isClimbingTypeSelected(type) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                        }
                        .frame(height: 16) // Fixed height to prevent layout shift
                    }
                    .frame(maxWidth: .infinity) // Equal width distribution
                }
            }
            .frame(maxWidth: .infinity) // Center align the entire HStack
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
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(Amenities.allCases, id: \.self) { amenity in
                    Button(action: {
                        viewModel.toggleAmenity(amenity)
                    }) {
                        HStack(spacing: 8) {
                            AmmenitiesIcons.icon(for: amenity)
                                .foregroundColor(viewModel.isAmenitySelected(amenity) ? AppTheme.appPrimary : Color.gray.opacity(0.5))
                            
                            Text(amenity.rawValue)
                                .font(.subheadline)
                                .foregroundColor(viewModel.isAmenitySelected(amenity) ? AppTheme.appTextPrimary : .secondary)
                            
                            Spacer()
                            
                            if viewModel.isAmenitySelected(amenity) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
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
}

#Preview {
    GymCreationView()
}
