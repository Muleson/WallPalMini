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
                            NavigationLink(destination: GymDetailManagementView(gym: gym)) {
                                GymRowView(gym: gym, viewModel: viewModel)
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
    let viewModel: GymManagementViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(gym.name)
                    .font(.headline)
                
                Spacer()
                
                // User's role badge
                Text(viewModel.getUserRoleForGym(gym))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(roleColor.opacity(0.2))
                    .foregroundColor(roleColor)
                    .cornerRadius(8)
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
            
            // Climbing types
            HStack {
                ForEach(gym.climbingType.prefix(3), id: \.self) { type in
                    Text(type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.appAccent.opacity(0.2))
                        .foregroundColor(AppTheme.appAccent)
                        .cornerRadius(4)
                }
                
                if gym.climbingType.count > 3 {
                    Text("+\(gym.climbingType.count - 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Staff count
            HStack {
                Image(systemName: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(gym.staffUserIds.count) staff members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var roleColor: Color {
        let role = viewModel.getUserRoleForGym(gym)
        switch role {
        case "Owner": return .blue
        case "Staff": return .green
        default: return .gray
        }
    }
}

struct GymDetailManagementView: View {
    let gym: Gym
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(gym.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = gym.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope")
                        Text(gym.email)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Management") {
                if gym.canAddStaff(userId: getCurrentUserId()) {
                    NavigationLink(destination: StaffManagementView(gym: gym)) {
                        Label("Manage Staff", systemImage: "person.2")
                    }
                }
                
                if gym.canCreateEvents(userId: getCurrentUserId()) {
                    NavigationLink(destination: EventManagementView(gym: gym)) {
                        Label("Manage Events", systemImage: "calendar")
                    }
                }
                
                NavigationLink(destination: GymProfileView(gym: gym)) {
                    Label("View Public Profile", systemImage: "eye")
                }
            }
            
            Section("Details") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                    
                    if let address = gym.location.address {
                        Text(address)
                    } else {
                        Text("Coordinates: \(gym.location.latitude, specifier: "%.4f"), \(gym.location.longitude, specifier: "%.4f")")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Climbing Types")
                        .font(.headline)
                    
                    Text(gym.climbingType.map { $0.rawValue.capitalized }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !gym.amenities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)
                        
                        Text(gym.amenities.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Info") {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(gym.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Gym Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getCurrentUserId() -> String {
        return FirebaseUserRepository().getCurrentAuthUser() ?? ""
    }
}

#Preview {
    GymManagementView(appState: AppState())
}
