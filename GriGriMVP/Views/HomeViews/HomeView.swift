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
    
    var body: some View {
        NavigationStack {
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
                PassCreationFlowView {
                    // This callback is triggered when a pass is successfully added
                    // You could refresh any pass-related data here if needed
                    print("Pass added successfully from HomeView")
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
            
            // Search and menu buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Search action
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(AppTheme.appPrimary)
                }
                
                Button(action: {
                    // Menu action
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(AppTheme.appPrimary)
                }
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
                        // Combine nearby events with fallback events sorted by date
                        ForEach(upcomingEventsForDisplay.prefix(5)) { event in
                            CompactEventCard(event: event) {
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
            } else if let featuredEvent = viewModel.featuredEvents.first {
                FeaturedEventCard(
                    event: featuredEvent,
                    onView: {
                        selectedEvent = featuredEvent // Also navigate from featured card
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
    
    // MARK: - Helper computed property for upcoming events
    private var upcomingEventsForDisplay: [EventItem] {
        let nearbyEvents = viewModel.nearbyEvents
        let minEventsToShow = 5
        
        // If we have enough nearby events, use them
        if nearbyEvents.count >= minEventsToShow {
            return Array(nearbyEvents.prefix(minEventsToShow))
        }
        
        // Otherwise, combine nearby events with other events sorted by date
        let allOtherEvents = viewModel.allEvents
            .filter { otherEvent in
                // Exclude events that are already in nearby events
                !nearbyEvents.contains { $0.id == otherEvent.id }
            }
            .sorted { $0.startDate < $1.startDate } // Sort by nearest date
        
        let combinedEvents = nearbyEvents + allOtherEvents
        return Array(combinedEvents.prefix(minEventsToShow))
    }
}

#Preview {
    HomeView(appState: AppState())
}
