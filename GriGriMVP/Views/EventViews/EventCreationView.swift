//
//  EventCreationView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 04/06/2025.
//

import Foundation
import SwiftUI

struct CreateEventView: View {
    let gym: Gym
    let onEventCreated: () -> Void
    
    @StateObject private var viewModel = CreateEventViewModel()
    @State private var name = ""
    @State private var description = ""
    @State private var eventDate = Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
    @State private var eventType: EventType = .social
    @State private var location = ""
    @State private var registrationRequired = false
    @State private var registrationLink = ""
    
    // Image selection states
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImageSourceSelection = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Event Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(name.count > 26 ? Color.red : Color.clear, lineWidth: 2)
                            )
                            .onChange(of: name) { oldValue, newValue in
                                if newValue.count > 26 {
                                    name = String(newValue.prefix(26))
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(name.count)/26")
                                .font(.caption2)
                                .foregroundColor(name.count > 26 ? .red : .secondary)
                        }
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    DatePicker("Date & Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach([EventType.competition, .social, .openDay, .settingTaster], id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }
                
                Section("Event Image") {
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 180, height: 224)
                                .clipped()
                                .cornerRadius(8)
                            
                            HStack {
                                Button("Change Image") {
                                    showImageSourceSelection = true
                                }
                                .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button("Remove") {
                                    selectedImage = nil
                                }
                                .foregroundColor(.red)
                            }
                            .font(.caption)
                        }
                    } else {
                        Button(action: {
                            showImageSourceSelection = true
                        }) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                Text("Add Event Image")
                            }
                            .frame(width: 180, height: 224)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section("Location") {
                    TextField("Location (optional)", text: $location)
                        .placeholder(when: location.isEmpty) {
                            Text(gym.name)
                                .foregroundColor(.gray)
                        }
                }
                
                Section("Registration") {
                    Toggle("Registration Required", isOn: $registrationRequired)
                    
                    if registrationRequired {
                        TextField("Registration Link (optional)", text: $registrationLink)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                }
                
                Section("Preview") {
                    EventCardPreviewView(
                        name: name,
                        description: description,
                        eventDate: eventDate,
                        eventType: eventType,
                        gymName: gym.name,
                        image: selectedImage
                    )
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task {
                            await createEvent()
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .confirmationDialog("Select Image Source", isPresented: $showImageSourceSelection) {
                Button("Take Photo") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        imageSourceType = .camera
                        showImagePicker = true
                    }
                }
                Button("Choose from Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    sourceType: imageSourceType,
                    allowsEditing: true
                )
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Creating event...")
                                .font(.headline)
                            
                            if selectedImage != nil {
                                Text("Uploading image...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        eventDate > Date()
    }
    
    private func createEvent() async {
        // Add selected image to viewModel
        if let image = selectedImage {
            viewModel.addImage(image)
        }
        
        // Use the viewModel's createEvent method
        await viewModel.createEvent(
            name: name,
            description: description,
            eventDate: eventDate,
            eventType: eventType,
            location: location.isEmpty ? gym.name : location,
            registrationRequired: registrationRequired,
            registrationLink: registrationLink.isEmpty ? nil : registrationLink,
            gym: gym
        )
        
        // Check if creation was successful
        if viewModel.errorMessage == nil {
            await MainActor.run {
                onEventCreated()
                dismiss()
            }
        }
    }
}
