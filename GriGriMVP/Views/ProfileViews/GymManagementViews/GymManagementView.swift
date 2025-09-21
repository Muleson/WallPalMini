//
//  GymManagementView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/05/2025.
//

import SwiftUI

/*
// COMMENTED OUT FOR TESTING - Sam 2025-08-23
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
                            .background(AppTheme.appPrimary)
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
                    .foregroundStyle(AppTheme.appPrimary)
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
            let filtered = viewModel.gyms.filter { gym in
                gym.name.localizedCaseInsensitiveContains(searchText) ||
                gym.location.address?.localizedCaseInsensitiveContains(searchText) == true
            }
                return filtered
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
            
            // Climbing types with icons
            HStack(spacing: 8) {
                ForEach(gym.climbingType.sortedForDisplay().prefix(4), id: \.self) { type in
                    HStack(spacing: 4) {
                        climbingTypeIcon(for: type)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(AppTheme.appPrimary)
                        
                        Text(formatClimbingType(type))
                            .font(.caption)
                            .foregroundColor(AppTheme.appPrimary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.appPrimary.opacity(0.2))
                    .cornerRadius(4)
                }
                
                if gym.climbingType.count > 4 {
                    Text("+\(gym.climbingType.count - 4)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
    
    private func climbingTypeIcon(for type: ClimbingTypes) -> Image {
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
    
    private func formatClimbingType(_ type: ClimbingTypes) -> String {
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
}

struct GymDetailManagementView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: GymDetailManagementViewModel
    @State private var showProfileImagePicker = false
    @State private var showImageActionDialog = false
    @State private var showImageViewer = false
    
    init(gym: Gym, appState: AppState) {
        self._viewModel = StateObject(wrappedValue: GymDetailManagementViewModel(gym: gym, appState: appState))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image
                profileImageView
                
                // Gym Name and Description
                VStack(spacing: 8) {
                    Text(viewModel.gym.name)
                        .font(.appHeadline)
                        .foregroundStyle(AppTheme.appTextPrimary)
                    
                    if let description = viewModel.gym.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Email
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                    Text(viewModel.gym.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Location
                locationView
                
                // Divider
                divider
                
                // Climbing Types
                climbingTypesSection
                
                // Divider
                divider
                
                // Amenities Section
                amenitiesSection
                
                // Divider
                divider
                
                // Management Section
                managementSection
                
                // Info Section
                infoSection
            }
            .padding()
        }
        .navigationTitle("Gym Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.appBackgroundBG)
        .refreshable {
            await viewModel.refreshGym()
        }
        .sheet(isPresented: $showProfileImagePicker) {
            ProfileImagePickerView(
                selectedImage: $viewModel.selectedProfileImage,
                isPresented: $showProfileImagePicker,
                onImageConfirmed: viewModel.handleImageSelected
            )
        }
        .sheet(isPresented: $showImageViewer) {
            if let profileImage = viewModel.gym.profileImage {
                ImageViewerSheet(imageMedia: profileImage)
            }
        }
        .confirmationDialog("Profile Image", isPresented: $showImageActionDialog) {
            Button("View Image") {
                showImageViewer = true
            }
            
            if viewModel.canEditGym {
                Button("Edit Photo") {
                    showProfileImagePicker = true
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("What would you like to do with the profile image?")
        }
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Gym updated successfully!")
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
    
    private var profileImageView: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Only show dialog if there's an image to view OR user can edit
                if viewModel.gym.profileImage != nil || viewModel.canEditGym {
                    showImageActionDialog = true
                }
            }) {
                Group {
                    if let profileImage = viewModel.gym.profileImage {
                        AsyncImage(url: profileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.appPrimary))
                                )
                        }
                        .frame(width: 128, height: 128)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppTheme.appPrimary, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 128, height: 128)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.gym.profileImage == nil && !viewModel.canEditGym)
            
            // Show hint text for editable images
            if viewModel.canEditGym {
                Text(viewModel.gym.profileImage != nil ? "Tap to view or edit" : "Tap to add photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var locationView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Location")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.secondary)
                
                Text(viewModel.formattedAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var climbingTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Climbing Types")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
                
                if viewModel.canEditGym {
                    if viewModel.isEditingClimbingTypes {
                        HStack(spacing: 16) {
                            Button("Cancel") {
                                viewModel.cancelClimbingTypesEditing()
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            Button("Save") {
                                Task {
                                    await viewModel.saveChanges()
                                    viewModel.isEditingClimbingTypes = false
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.appPrimary)
                        .fontWeight(.semibold)
                        .disabled(viewModel.isLoading)
                    }
                    } else {
                        Button("Edit") {
                            viewModel.enterClimbingTypesEditMode()
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            
            if viewModel.isEditingClimbingTypes {
                editableClimbingTypesGrid
            } else {
                readOnlyClimbingTypesGrid
            }
        }
    }
    
    private var editableClimbingTypesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
            ForEach(ClimbingTypes.allCases.sortedForDisplay(), id: \.self) { type in
                Button(action: {
                    viewModel.toggleClimbingType(type)
                }) {
                    HStack(spacing: 8) {
                        viewModel.climbingTypeIcon(for: type)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(viewModel.isClimbingTypeSelected(type) ? AppTheme.appPrimary : Color.gray.opacity(0.5))
                        
                        Text(viewModel.formatClimbingType(type))
                            .font(.subheadline)
                            .foregroundColor(viewModel.isClimbingTypeSelected(type) ? AppTheme.appTextPrimary : .secondary)
                        
                        Spacer()
                        
                        if viewModel.isClimbingTypeSelected(type) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(viewModel.isClimbingTypeSelected(type) ? Color.gray.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var readOnlyClimbingTypesGrid: some View {
        HStack(spacing: 36) {
            ForEach(viewModel.gym.climbingType.sortedForDisplay(), id: \.self) { type in
                VStack(spacing: 4) {
                    viewModel.climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .foregroundColor(AppTheme.appPrimary)
                    
                    Text(viewModel.formatClimbingType(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
    
    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Management")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                if viewModel.canManageStaff {
                   /* NavigationLink(destination: StaffManagementView(gym: viewModel.gym)) {
                        managementRowView(
                            icon: "person.2",
                            title: "Manage Staff"
                        )
                    } */
                }
                
                if viewModel.canManageEvents {
                    NavigationLink(destination: EventManagementView(gym: viewModel.gym)) {
                        managementRowView(
                            icon: "calendar",
                            title: "Manage Events"
                        )
                    }
                }
                
                NavigationLink {
                    // TODO: Fix this - should use proper gym from list or different view model
                    // GymProfileView(gym: viewModel.gym, appState: appState)
                    Text("Gym Profile - Fix Required")
                } label: {
                    managementRowView(
                        icon: "eye",
                        title: "View Public Profile"
                    )
                }
            }
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Info")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
            }
            
            HStack {
                Text("Created")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                
                Spacer()
                
                Text(viewModel.formattedCreatedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AppTheme.appContentBG)
            .cornerRadius(12)
        }
    }
    
    private func managementRowView(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.appPrimary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.appTextPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppTheme.appContentBG)
        .cornerRadius(12)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(AppTheme.appSecondary)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Amenities")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                Spacer()
                
                if viewModel.canEditGym {
                    if viewModel.isEditingAmenities {
                        HStack(spacing: 16) {
                            Button("Cancel") {
                                viewModel.cancelAmenitiesEditing()
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            Button("Save") {
                                Task {
                                    await viewModel.saveChanges()
                                    viewModel.isEditingAmenities = false
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.appPrimary)
                        .fontWeight(.semibold)
                        .disabled(viewModel.isLoading)
                    }
                    } else {
                        Button("Edit") {
                            viewModel.enterAmenitiesEditMode()
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            
            if viewModel.isEditingAmenities {
                editableAmenitiesGrid
            } else {
                readOnlyAmenitiesGrid
            }
        }
    }
    
    private var editableAmenitiesGrid: some View {
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
    
    private var readOnlyAmenitiesGrid: some View {
        Group {
            if !viewModel.gym.amenities.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(viewModel.gym.amenities, id: \.self) { amenity in
                        HStack(spacing: 8) {
                            AmmenitiesIcons.icon(for: amenity)
                                .foregroundColor(AppTheme.appPrimary)
                            
                            Text(amenity.rawValue)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.secondary)
                    
                    Text("No amenities listed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(AppTheme.appContentBG.opacity(0.5))
                .cornerRadius(12)
            }
        }
    }
}

// Create a simple image viewer sheet
struct ImageViewerSheet: View {
    let imageMedia: MediaItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: imageMedia.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationTitle("Profile Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    GymManagementView(appState: AppState())
}
*/
// END COMMENTED OUT FOR TESTING - Sam 2025-08-23
