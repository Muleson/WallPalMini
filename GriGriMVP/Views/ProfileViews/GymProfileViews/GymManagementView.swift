//
//  GymManagementView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import SwiftUI

struct GymManagementView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = GymManagementViewModel()
    @State private var showingCreateGym = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading gyms...")
                    Spacer()
                } else if viewModel.gyms.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Gyms Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first gym to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showingCreateGym = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Create Gym")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.appAccent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredGyms) { gym in
                            NavigationLink(destination: GymDetailView(gym: gym)) {
                                GymRowView(gym: gym)
                            }
                        }
                        .onDelete(perform: deleteGyms)
                    }
                    .searchable(text: $searchText, prompt: "Search gyms...")
                    .refreshable {
                        await viewModel.loadGyms()
                    }
                }
            }
            .navigationTitle("Gym Management")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingCreateGym = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .foregroundStyle(AppTheme.appAccent)
                }
            }
            .sheet(isPresented: $showingCreateGym) {
                GymCreationView()
            }
            .onAppear {
                Task {
                    await viewModel.loadGyms()
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
        }
    }
    
    private var filteredGyms: [Gym] {
        if searchText.isEmpty {
            return viewModel.gyms
        } else {
            return viewModel.gyms.filter { gym in
                gym.name.localizedCaseInsensitiveContains(searchText) ||
                gym.location.address?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func deleteGyms(offsets: IndexSet) {
        for index in offsets {
            let gym = filteredGyms[index]
            Task {
                await viewModel.deleteGym(gym)
            }
        }
    }
}

struct GymRowView: View {
    let gym: Gym
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(gym.name)
                    .font(.headline)
                
                Spacer()
                
                ForEach(gym.climbingType, id: \.self) { type in
                    Text(type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.appAccent.opacity(0.2))
                        .foregroundColor(AppTheme.appAccent)
                        .cornerRadius(8)
                }
            }
            
            if let address = gym.location.address {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            if !gym.amenities.isEmpty {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(gym.amenities.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if gym.amenities.count > 3 {
                        Text("+ \(gym.amenities.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct GymDetailView: View {
    let gym: Gym
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(gym.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(gym.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Description
                if let description = gym.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                    }
                }
                
                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                    
                    if let address = gym.location.address {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(address)
                        }
                    }
                    
                    Text("Coordinates: \(gym.location.latitude, specifier: "%.4f"), \(gym.location.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Climbing Types
                VStack(alignment: .leading, spacing: 8) {
                    Text("Climbing Types")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(gym.climbingType, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.appAccent.opacity(0.2))
                                .foregroundColor(AppTheme.appAccent)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Amenities
                if !gym.amenities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(gym.amenities, id: \.self) { amenity in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(amenity)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Created Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created")
                        .font(.headline)
                    
                    Text(gym.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Gym Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    GymManagementView(appState: AppState())
}
