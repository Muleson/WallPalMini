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

    @State private var selectedEvent: EventItem?
    @State private var navigateToPassCreation = false // Renamed for clarity
    @State private var showMenuBar = false
    // @State private var showDataInjector = false // TEMPORARY: Dev tool
    
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
                                nearbyPassSection

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
                        // TEMPORARY: Dev tool button (leading) - COMMENTED OUT
                        /*
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showDataInjector = true
                            }) {
                                Image(systemName: "cylinder.split.1x2")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                        */

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showMenuBar.toggle()
                                }
                            }) {
                                Image(systemName: showMenuBar ? "xmark" : "line.3.horizontal")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(showMenuBar ? AppTheme.appPrimary : .primary)
                            }
                        }
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
                                // Navigate to Passes tab instead of going back to HomeView
                                print("Pass added successfully from HomeView, navigating to Passes tab")
                                navigateToPassCreation = false
                                appState.deepLinkManager.setPendingDeepLink(.passes)
                            },
                            onCancel: {
                                navigateToPassCreation = false
                            }
                        )
                    }
                    // TEMPORARY: Dev tool sheet - COMMENTED OUT
                    /*
                    .sheet(isPresented: $showDataInjector) {
                        SimplifiedDataInjectorView()
                    }
                    */
                }
                
                // Menu overlay - positioned outside NavigationStack to cover everything
                if showMenuBar {
                    // Enhanced semi-transparent background with blur
                    ZStack {
                        Color.black.opacity(0.25)
                        
                        // Add subtle blur effect to background content
                        Rectangle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                    }
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showMenuBar = false
                        }
                    }
                    
                    // Menu panel with improved shadow and materials
                    HStack(spacing: 0) {
                        Spacer()
                        
                        MenuBarView(appState: appState) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showMenuBar = false
                            }
                        }
                        .frame(width: geometry.size.width * 0.75)
                        .frame(maxHeight: .infinity)
                        .clipped()
                        .shadow(color: .black.opacity(0.15), radius: 20, x: -8, y: 0)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: -2, y: 0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                    .ignoresSafeArea(.all)
                }
            }
        }
        .onAppear {
            viewModel.loadHomeEvents()
            viewModel.fetchUserAndFavorites()

            // Ensure nearest gym is loaded when view appears
            // This handles cases where passes are loaded but nearest gym hasn't been calculated
            if viewModel.nearestGym == nil {
                viewModel.findNearestGym()
            }
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
    private var nearbyPassSection: some View {
        if viewModel.isLoadingGyms {
            NearbyGymRowSkeleton()
                .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
        } else {
            NearbyPassRow(
                gym: viewModel.nearestGym,
                distance: viewModel.distanceToNearestGym,
                onViewPass: {
                    // Navigate to Passes tab (tab 1)
                    appState.deepLinkManager.setPendingDeepLink(.passes)
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
                    },
                    onSave: {
                        viewModel.toggleFavorite(for: featuredEvent)
                    },
                    isSaved: viewModel.isEventFavorited(featuredEvent)
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
