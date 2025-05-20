//
//  HomeView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var viewModel = HomeViewModel()
    
    @State private var navigateToPasses = false
    
    var body: some View {
        NavigationStack {
            ScrollView  {
                // Main content in a ScrollView
                VStack(alignment: .center, spacing: 8) {
                    // Quick action button
                        NavigationLink {
                            PassesRootView() // Navigate directly to PassesRootView
                        } label: {
                            VStack {
                                Text("View Pass")
                                    .font(.appHeadline)
                            }
                            .frame(maxWidth: 306)
                            .padding(.vertical, 4)
                            .foregroundColor(.white)
                            .background(AppTheme.appAccent)
                            .cornerRadius(15)
                        }
                    .padding(.horizontal)
                    
                    // Featured Events section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Featured Events")
                            .font(.appHeadline)
                            .foregroundColor(AppTheme.appTextPrimary)
                            .padding(.leading, 16)
                        
                        if viewModel.isLoadingEvents {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if viewModel.featuredEvents.isEmpty {
                            Text("No featured events available")
                                .font(.appBody)
                                .foregroundColor(AppTheme.appTextLight)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.featuredEvents) { event in
                                        EventCardView(event: event)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Events from Favorite Gyms section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Events at Your Favorite Gyms")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                                .padding(.leading, 16)
                            
                            if viewModel.isLoadingEvents {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if viewModel.favoriteGymEvents.isEmpty {
                                Text("No events from your favorite gyms")
                                    .font(.appBody)
                                    .foregroundColor(AppTheme.appTextLight)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.favoriteGymEvents) { event in
                                            EventCardView(event: event)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 24)
                        
                        // Nearby Events section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Events Near You")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                                .padding(.leading, 16)
                            
                            if viewModel.isLoadingEvents {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if viewModel.nearbyEvents.isEmpty {
                                Text("No events nearby")
                                    .font(.appBody)
                                    .foregroundColor(AppTheme.appTextLight)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.nearbyEvents) { event in
                                            EventCardView(event: event)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 24)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Hello, \(appState.user?.firstName ?? "")")
        .navigationDestination(isPresented: $navigateToPasses) {
            PassesRootView()
        }
        .onAppear {
            viewModel.fetchEvents()
            // Apply filters after fetching events
            viewModel.applyFilters()
        }
    }
}

#Preview {
    HomeView(appState: AppState())
}
