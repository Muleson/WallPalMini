//
//  StaffManagementView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

/*

import SwiftUI

struct StaffManagementView: View {
    let gym: Gym
    @StateObject private var viewModel: StaffViewModel
    @State private var showingAddStaff = false
    
    init(gym: Gym) {
        self.gym = gym
        _viewModel = StateObject(wrappedValue: StaffViewModel(gym: gym))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading staff...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.staffMembers.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Staff Members")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add staff members to help manage events and content for your gym")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if gym.canAddStaff(userId: viewModel.currentUserId ?? "") {
                            Button("Add First Staff Member") {
                                showingAddStaff = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Staff list
                    List {
                        ForEach(viewModel.staffMembers) { staff in
                            StaffRowView(staff: staff) {
                                Task {
                                    await viewModel.removeStaff(staff.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Staff Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if gym.canAddStaff(userId: viewModel.currentUserId ?? "") {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Staff") {
                            showingAddStaff = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddStaff) {
                AddStaffView(gym: gym) {
                    Task {
                        await viewModel.loadStaff()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadStaff()
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

struct StaffRowView: View {
    let staff: StaffMember
    let onRemove: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(staff.name)
                        .font(.headline)
                    
                    Text(staff.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Added: \(staff.addedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            
            // Capabilities
            HStack {
                Label("Can create events", systemImage: "calendar.badge.plus")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label("Can post content", systemImage: "square.and.pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Remove Staff Member", isPresented: $showingDeleteConfirmation) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(staff.name) from your gym staff? They will no longer be able to manage events or post content.")
        }
    }
}

struct AddStaffView: View {
    let gym: Gym
    let onStaffAdded: () -> Void
    
    @StateObject private var viewModel = AddStaffViewModel()
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                VStack(spacing: 16) {
                    TextField("Search by email", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .onSubmit {
                            Task {
                                await viewModel.searchUsers(query: searchText)
                            }
                        }
                    
                    Button("Search") {
                        Task {
                            await viewModel.searchUsers(query: searchText)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                
                Divider()
                
                // Search results
                if viewModel.isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No users found")
                            .font(.headline)
                        
                        Text("Try searching with a different email address")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.searchResults.isEmpty {
                    List(viewModel.searchResults) { user in
                        UserSearchRowView(user: user) {
                            Task {
                                await viewModel.addStaffMember(to: gym.id, userId: user.id)
                                if viewModel.errorMessage == nil {
                                    onStaffAdded()
                                    dismiss()
                                }
                            }
                        }
                    }
                } else {
                    // Initial state
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Search for Users")
                            .font(.headline)
                        
                        Text("Enter an email address to find users to add as staff members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Add Staff Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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

struct UserSearchRowView: View {
    let user: User
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Add") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StaffManagementView(gym: SampleData.gyms[0])
}
*/
