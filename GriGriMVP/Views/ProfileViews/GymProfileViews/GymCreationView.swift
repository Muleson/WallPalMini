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
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    TextField("Gym Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    TextField("Description (Optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Location Section
                Section("Location") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Address", text: $viewModel.address)
                            .textInputAutocapitalization(.words)
                            .onChange(of: viewModel.address) { _, _ in
                                // Auto-geocode when user stops typing
                                viewModel.geocodeAddress()
                            }
                        
                        HStack {
                            Button(action: viewModel.getCurrentLocation) {
                                HStack {
                                    if viewModel.isLocationLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "location.fill")
                                    }
                                    Text("Use Current Location")
                                }
                                .foregroundColor(.blue)
                            }
                            .disabled(viewModel.isLocationLoading)
                            
                            Spacer()
                            
                            if viewModel.latitude != 0.0 && viewModel.longitude != 0.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if viewModel.latitude != 0.0 && viewModel.longitude != 0.0 {
                            HStack {
                                Text("Coordinates:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(viewModel.latitude, specifier: "%.4f"), \(viewModel.longitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Climbing Types Section
                Section("Climbing Types") {
                    ForEach(ClimbingTypes.allCases, id: \.self) { type in
                        HStack {
                            Text(type.rawValue.capitalized)
                            Spacer()
                            if viewModel.selectedClimbingTypes.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.selectedClimbingTypes.contains(type) {
                                viewModel.selectedClimbingTypes.remove(type)
                            } else {
                                viewModel.selectedClimbingTypes.insert(type)
                            }
                        }
                    }
                }
                
                // Amenities Section
                Section("Amenities") {
                    HStack {
                        TextField("Add amenity", text: $viewModel.newAmenity)
                            .onSubmit {
                                viewModel.addAmenity()
                            }
                        
                        Button("Add") {
                            viewModel.addAmenity()
                        }
                        .disabled(viewModel.newAmenity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    ForEach(viewModel.amenities, id: \.self) { amenity in
                        HStack {
                            Text(amenity)
                            Spacer()
                            Button(action: {
                                viewModel.removeAmenity(amenity)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Gym")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task {
                            await viewModel.createGym()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Gym created successfully!")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Creating gym...")
                                .font(.headline)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }
}

#Preview {
    GymCreationView()
}
