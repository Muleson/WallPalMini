//
//  GymProfileView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct GymProfileView: View {
    @StateObject private var viewModel: GymProfileViewModel
    @Environment(\.openURL) private var openURL
    @State private var showVisitOptions: Bool = false
    @State private var selectedEvent: EventItem? = nil
    @State private var showShareSheet = false

    let enableRefresh: Bool

    init(gym: Gym, gymsViewModel: GymsViewModel? = nil, appState: AppState? = nil, enableRefresh: Bool = true) {
        let finalAppState = appState ?? AppState()
        let finalGymsViewModel = gymsViewModel ?? GymsViewModel(appState: finalAppState)

        self._viewModel = StateObject(wrappedValue: GymProfileViewModel(
            gym: gym,
            gymsViewModel: finalGymsViewModel,
            appState: finalAppState
        ))
        self.enableRefresh = enableRefresh
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Profile Image
                profileImageView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Gym Name
                Text(viewModel.gym.name)
                    .font(.appHeadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Gym Location
                locationView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Climbing Types Icons
                climbingTypesIconsView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                // Action Buttons (Favorite & Visit)
                actionButtonsView
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Tab Picker
                tabPickerView
                    .padding(.horizontal)
                
                // Content based on selected tab
                Group {
                    if viewModel.shouldShowEventsContent {
                        gymEventsContent
                    } else {
                        gymInfoContent
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.appPrimary)
                }
            }
        }
        .background(AppTheme.appBackgroundBG)
        .conditionalRefreshable(enabled: enableRefresh) {
            await viewModel.refreshGymData()
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .confirmationDialog("Visit \(viewModel.gym.name)", isPresented: $showVisitOptions, titleVisibility: .visible) {
            Button("Open in Maps") {
                if let url = viewModel.openGymInMaps() {
                    openURL(url)
                }
            }

            if let websiteString = viewModel.gym.website,
               let websiteURL = URL(string: websiteString) {
                Button("View Website") {
                    openURL(websiteURL)
                }
            }

            Button("Cancel", role: .cancel) { }
        }
        .navigationDestination(item: $selectedEvent) { event in
            EventPageView(event: event)
        }
        .task {
            await viewModel.loadGymData()
        }
        .shareSheet(isPresented: $showShareSheet, activityItems: ShareLinkHelper.gymShareItems(gym: viewModel.gym))
    }
    
    private var profileImageView: some View {
        CachedGymImageView(gym: viewModel.gym, size: 128)
    }
    
    private var locationView: some View {
        HStack {
            Text(viewModel.gym.location.formattedAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var climbingTypesIconsView: some View {
        HStack(spacing: 36) {
            ForEach(viewModel.gym.climbingType.sortedForDisplay(), id: \.self) { type in
                VStack(spacing: -4) {
                    climbingTypeIcon(for: type)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .foregroundColor(AppTheme.appPrimary)
                    
                    Text(formatClimbingType(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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
            return "Bouldering"
        case .sport:
            return "Sport"
        case .board:
            return "Board"
        case .gym:
            return "Gym"
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Favorite Button
            PrimaryActionButton.toggle(
                viewModel.isFavorite ? "Favourited" : "Favourite",
                isEngaged: viewModel.isFavorite
            ) {
                Task {
                    await viewModel.toggleFavorite()
                }
            }
            
            // Visit Button (Placeholder)
            PrimaryActionButton.primary("Visit") {
                showVisitOptions = true
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var tabPickerView: some View {
        HStack(spacing: 0) {
            ForEach(GymProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    viewModel.selectTab(tab)
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.appBody)
                            .fontWeight(viewModel.selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(viewModel.selectedTab == tab ? AppTheme.appPrimary : .secondary)
                        
                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? AppTheme.appPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var gymInfoContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hours Section
            if let hours = viewModel.gym.operatingHours {
                GymHoursCard(hours: hours)
            }
            
            // Amenities Section
            amenitiesSection
            
            // Website & Pricing Card
            WebsitePriceCard(websiteURL: viewModel.gym.website)
        }
    }
    
    private var gymEventsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Upcoming Events Section
            upcomingEventsSection
        }
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Loading indicator
            if viewModel.isLoadingEvents {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading events...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Featured Event Section - show if there's a next featured event
            if let featuredEvent = viewModel.nextFeaturedEvent {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Upcoming Event")
                            .font(.appSubheadline)
                            .foregroundStyle(AppTheme.appTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    HomeFeaturedEventCard(
                        event: featuredEvent,
                        onView: {
                            selectedEvent = featuredEvent
                        },
                        onRegister: {
                            // TODO: Handle registration
                        },
                        onAddToCalendar: {
                            // TODO: Add to calendar
                        },
                        onSave: {
                            viewModel.toggleFavorite(for: featuredEvent)
                        },
                        isSaved: viewModel.isEventFavorited(featuredEvent)
                    )
                    .padding(.horizontal)
                }
            }
            
            // Gym Classes Section - show if there are upcoming classes
            if !viewModel.upcomingClassEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Classes")
                            .font(.appSubheadline)
                            .foregroundStyle(AppTheme.appTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.upcomingClassEvents.prefix(10)) { event in
                                CompactEventCard(event: event) {
                                    selectedEvent = event
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8) // Add bottom padding to prevent shadow clipping
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.hasAmenities {
                HStack {
                    Text("Amenities")
                        .font(.appSubheadline)
                        .foregroundStyle(AppTheme.appTextPrimary)
                    Spacer()
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(viewModel.gym.amenities, id: \.self) { amenity in
                        HStack(spacing: 8) {
                            AmmenitiesIcons.icon(for: amenity)
                                .foregroundColor(AppTheme.appPrimary)
                            Text(amenity.rawValue)
                                .font(.appBody)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - View Extension for Conditional Refreshable
extension View {
    @ViewBuilder
    func conditionalRefreshable(enabled: Bool, action: @escaping @Sendable () async -> Void) -> some View {
        if enabled {
            self.refreshable(action: action)
        } else {
            self
        }
    }
}

#Preview {
    NavigationView {
        GymProfileView(gym: SampleData.gyms[1])
    }
}
