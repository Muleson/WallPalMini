//
//  HomeView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var navigateToPasses = false
    @State private var selectedEvent: EventItem?
    @State private var navigateToPassCreation = false // Renamed for clarity
    @State private var showMenuBar = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main NavigationStack with content
                NavigationStack {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                            // Greeting Section with reduced top spacing
                            greetingSection
                                .padding(.top, -AppTheme.Spacing.medium) // Negative padding to reduce space from nav title
                            
                            // Content with normal spacing
                            VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                                
                                // Nearby Gym Card
                                nearbyGymSection
                                
                                // Events Sections
                                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                                    happeningNextSection
                                    comingUpSection
                                }
                            }
                        }
                    }
                    .background(Color(AppTheme.appBackgroundBG))
                    .navigationTitle("Home")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showMenuBar = true
                                }
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                    }
                    .navigationDestination(isPresented: $navigateToPasses) {
                        PassesRootView(appState: appState)
                    }
                    // Add navigation destination for event details
                    .navigationDestination(item: $selectedEvent) { event in
                        EventPageView(event: event)
                    }
                    // Updated navigation destination for pass creation flow
                    .navigationDestination(isPresented: $navigateToPassCreation) {
                        PassCreationFlowView(
                            onPassAdded: {
                                // This callback is triggered when a pass is successfully added
                                // Navigate to PassRootView instead of going back to HomeView
                                print("Pass added successfully from HomeView, navigating to PassRootView")
                                navigateToPassCreation = false
                                navigateToPasses = true
                            },
                            onCancel: {
                                navigateToPassCreation = false
                            }
                        )
                    }
                }
                
                // Menu overlay - positioned outside NavigationStack to cover everything
                if showMenuBar {
                    // Semi-transparent background
                    Color.black.opacity(0.4)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMenuBar = false
                            }
                        }
                    
                    // Menu panel
                    HStack(spacing: 0) {
                        Spacer()
                        
                        MenuBarView(appState: appState) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMenuBar = false
                            }
                        }
                        .frame(width: geometry.size.width * 0.75)
                        .frame(maxHeight: .infinity)
                        .clipped()
                        .shadow(color: .black.opacity(0.3), radius: 10, x: -5, y: 0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                    }
                    .ignoresSafeArea(.all)
                }
            }
        }
        .onAppear {
            viewModel.fetchEvents()
            viewModel.fetchUserAndFavorites()
        }

        .alert(isPresented: $viewModel.hasError, content: {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
    // MARK: - Greeting Section
    @ViewBuilder
    private var greetingSection: some View {
        if appState.user == nil {
            GreetingSectionSkeleton()
        } else {
            GreetingSection(userName: appState.user?.firstName)
        }
    }
    
    // MARK: - Nearby Gym Section
    @ViewBuilder
    private var nearbyGymSection: some View {
        if viewModel.isLoadingGyms {
            NearbyGymRowSkeleton()
                .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
        } else {
            NearbyGymRow(
                gym: viewModel.nearestGym,
                distance: viewModel.distanceToNearestGym,
                onViewPass: {
                    navigateToPasses = true
                },
                onAddPass: {
                    navigateToPassCreation = true // Updated to use pass creation flow
                },
                onSetActivePass: {
                    guard let gym = viewModel.nearestGym else { return false }
                    return viewModel.setActivePassForGym(gym)
                }
            )
            .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
        }
    }
    
        // MARK: - Coming Up Section
    @ViewBuilder
    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionTitleSpacing) {
            Text("Coming Up")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
            
            if viewModel.isLoadingEvents {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.cardSpacing) {
                        ForEach(0..<4, id: \.self) { _ in
                            HomeCompactEventCardSkeleton()
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.cardSpacing) {
                        // Use the processed upcoming events from the view model
                        ForEach(viewModel.upcomingEvents.prefix(4)) { event in
                            HomeCompactEventCard(event: event) {
                                selectedEvent = event // Set selected event for navigation
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
                }
            }
        }
    }
    
    // Note: The upcomingEventsForDisplay computed property is no longer needed
    // since we're using batch loading with processed events from the view model
    
    // MARK: - Happening Next Section
    @ViewBuilder
    private var happeningNextSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionTitleSpacing) {
            Text("Happening next")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
            
            if viewModel.isLoadingEvents {
                HomeFeaturedEventCardSkeleton()
                    .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
            } else if let featuredEvent = viewModel.featuredEvent {
                HomeFeaturedEventCard(
                    event: featuredEvent,
                    onView: {
                        selectedEvent = featuredEvent
                    },
                    onRegister: {
                        // Register for event
                        print("Register for event: \(featuredEvent.name)")
                    },
                    onAddToCalendar: {
                        viewModel.addEventToCalendar(featuredEvent)
                    }
                )
                .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
            } else {
                Text("No featured events available")
                    .font(.appBody)
                    .foregroundColor(AppTheme.appTextLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}

#Preview {
    HomeView(appState: AppState())
}
