//
//  HomeView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var viewModel = HomeViewModel()
    @State private var navigateToPasses = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
                PassesRootView()
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
                // Add pass action - could navigate to gym search or pass purchase
                print("Add pass tapped")
            }
        )
        .padding(.horizontal, 12)
        .padding(.top, 24)
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
                        // Navigate to event details
                        print("View event: \(featuredEvent.name)")
                    },
                    onRegister: {
                        // Register for event
                        print("Register for event: \(featuredEvent.name)")
                    }
                )
                .padding(.horizontal, 20)
            } else {
                Text("No featured events available")
                    .font(.appBody)
                    .foregroundColor(AppTheme.appTextLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
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
                        // Pre-defined event cards
                        CompactEventCard.communityClimb {
                            print("Community Climb tapped")
                        }
                        
                        CompactEventCard.vertigoFiesta {
                            print("Vertigo Fiesta tapped")
                        }
                        
                        // Dynamic event cards from your data
                        ForEach(viewModel.nearbyEvents.prefix(3)) { event in
                            CompactEventCard(event: event) {
                                print("Event tapped: \(event.name)")
                            }
                        }
                        
                        // Show route setting if no nearby events
                        if viewModel.nearbyEvents.isEmpty {
                            CompactEventCard.routeSetting {
                                print("Route Setting tapped")
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.bottom, 32)
    }
}

#Preview {
    HomeView(appState: AppState())
}
