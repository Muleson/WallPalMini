//
//  EventManagementView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import SwiftUI

struct EventManagementView: View {
    let gym: Gym
    @StateObject private var viewModel: EventManagementViewModel
    @State private var showingCreateEvent = false
    
    init(gym: Gym) {
        self.gym = gym
        _viewModel = StateObject(wrappedValue: EventManagementViewModel(gym: gym))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading events...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.gymEvents.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Events")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create events to engage with your gym community")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Create First Event") {
                            showingCreateEvent = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Events list
                    List {
                        ForEach(viewModel.gymEvents) { event in
                            EventRowView(event: event) {
                                // Edit event (future feature)
                            } onDelete: {
                                Task {
                                    await viewModel.deleteEvent(event.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create Event") {
                        showingCreateEvent = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(gym: gym) {
                    Task {
                        await viewModel.loadEvents()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadEvents()
                }
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
        }
    }
}

struct EventRowView: View {
    let event: EventItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                    
                    Text(event.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(event.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.appAccent.opacity(0.2))
                        .foregroundColor(AppTheme.appAccent)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit") {
                        onEdit()
                    }
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }
            
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if event.registrationRequired {
                Label("Registration Required", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(event.name)'? This action cannot be undone.")
        }
    }
}

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
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    DatePicker("Date & Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach([EventType.competition, .social, .openDay, .settingTaster], id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
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
                    }
                }
                
                Section("Preview") {
                    EventPreviewView(
                        name: name,
                        description: description,
                        eventDate: eventDate,
                        eventType: eventType,
                        gymName: gym.name
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
                            
                            if viewModel.errorMessage == nil {
                                onEventCreated()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
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
                        
                        ProgressView("Creating event...")
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
}

struct EventPreviewView: View {
    let name: String
    let description: String
    let eventDate: Date
    let eventType: EventType
    let gymName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name.isEmpty ? "Event Name" : name)
                    .font(.headline)
                    .foregroundColor(name.isEmpty ? .secondary : .primary)
                
                Spacer()
                
                Text(eventType.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.appAccent.opacity(0.2))
                    .foregroundColor(AppTheme.appAccent)
                    .cornerRadius(4)
            }
            
            Text(eventDate.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(description.isEmpty ? "Event description..." : description)
                .font(.body)
                .foregroundColor(description.isEmpty ? .secondary : .primary)
                .lineLimit(3)
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                Text(gymName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Helper view extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    EventManagementView(gym: SampleData.gyms[0])
}
