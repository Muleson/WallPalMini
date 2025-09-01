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
            NavigationStack {
                ZStack {
                    // Main HomeView Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header Section
                            headerSection
                            
                            // Greeting Section
                            greetingSection
                            
                            // Nearby Gym Card
                            nearbyGymSection
                            
                            // Events Sections
                            VStack(spacing: 24) {
                                happeningNextSection
                                comingUpSection
                            }
                            .padding(.top, 16)
                        }
                    }
                    .background(Color(AppTheme.appBackgroundBG))
                    .offset(x: showMenuBar ? -geometry.size.width * 0.5 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showMenuBar)
                    
                    // Menu Overlay
                    if showMenuBar {
                        // Background overlay to dismiss menu
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showMenuBar = false
                            }
                        
                        // Menu Bar View
                        HStack {
                            Spacer()
                            
                            MenuBarView(appState: appState)
                                .frame(width: geometry.size.width * 0.5)
                                .transition(.move(edge: .trailing))
                        }
                        .animation(.easeInOut(duration: 0.3), value: showMenuBar)
                    }
                }
                .navigationBarHidden(true)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(AppTheme.appPrimary)
            
            Text("Crahg")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
            
            Spacer()
            
            // Menu button
            Button(action: {
                showMenuBar = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(AppTheme.appPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Greeting Section
    private var greetingSection: some View {
        GreetingSection(userName: appState.user?.firstName)
    }
    
    // MARK: - Nearby Gym Section
    private var nearbyGymSection: some View {
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
        .padding(.horizontal, 12)
        .padding(.top, 24)
    }
    
        // MARK: - Coming Up Section
    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coming Up")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .padding(.horizontal, 16)
            
            if viewModel.isLoadingEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Use the processed upcoming events from the view model
                        ForEach(viewModel.upcomingEvents.prefix(4)) { event in
                            HomeCompactEventCard(event: event) {
                                selectedEvent = event // Set selected event for navigation
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.bottom, 32)
    }
    
    // Note: The upcomingEventsForDisplay computed property is no longer needed
    // since we're using batch loading with processed events from the view model
    
    // MARK: - Happening Next Section
    private var happeningNextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Happening next")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .padding(.horizontal, 16)
            
            if viewModel.isLoadingEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
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
                .padding(.horizontal, 12)
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
