//
//  EventManagementView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import SwiftUI
import PhotosUI

struct EventManagementView: View {
    let gym: Gym
    @StateObject private var viewModel: EventManagementViewModel
    @State private var showingCreateEvent = false
    @State private var editingEvent: EventItem?
    
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
                                // Edit event functionality
                                editingEvent = event
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
                        .background(AppTheme.appContentBG.opacity(0.2))
                        .foregroundColor(AppTheme.appPrimary)
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



// MARK: - Event Card Preview matching EventCardView format
struct EventCardPreviewView: View {
    let name: String
    let description: String
    let eventDate: Date
    let eventType: EventType
    let gymName: String
    let image: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Media display (matching EventCardView)
            ZStack(alignment: .topTrailing) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 224)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 180, height: 224)
                        .overlay(
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
                
                // Favorite button (disabled for preview)
                Image(systemName: "heart")
                    .foregroundColor(.white)
                    .font(.system(size: 22))
                    .padding(8)
                    .shadow(radius: 2)
                    .padding([.top, .trailing], 8)
            }

            // Info box at bottom (matching EventCardView)
            VStack(spacing: 8) {
                // Event name
                HStack {
                    Text(name.isEmpty ? "Event Name" : name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(name.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                }
                
                // Gym info and time on same line
                HStack {
                    // Gym profile picture placeholder
                    Image(systemName: "building.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                    
                    // Gym name text
                    Text(gymName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Time relative to current date
                    Text(timeUntilEvent(eventDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .frame(width: 180, height: 284)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 4)
    }
    
    // Helper function to calculate relative time until event
    private func timeUntilEvent(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if date < now {
            return "Ended"
        }
        
        let components = calendar.dateComponents([.day, .hour], from: now, to: date)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "Tomorrow" : "\(days) days"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hours"
        } else {
            return "Soon"
        }
    }
}

// Helper extension for placeholder modifier
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
