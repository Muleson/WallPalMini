//
//  GymsView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/06/2025.
//

import SwiftUI

struct GymsListView: View {
    @StateObject private var viewModel: GymsViewModel
    @ObservedObject private var locationService = LocationService.shared
    
    init(appState: AppState) {
        self._viewModel = StateObject(wrappedValue: GymsViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    // Favourites Section - only show if there are favorite gyms
                    if !viewModel.favoriteGyms.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.cardSpacing) {
                            HStack {
                                Text("Favourites")
                                    .font(.appHeadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.cardSpacing) {
                                    ForEach(viewModel.favoriteGyms) { gym in
                                        CompactGymCard(gym: gym, viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                .padding(.bottom, AppTheme.Spacing.sectionContentSpacing) // Add bottom padding to prevent shadow clipping
                            }
                        }
                    }
                    
                    // Discover Section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.cardSpacing) {
                        HStack {
                            Text("Discover")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                            
                            Spacer()

                            Button(action: {
                                viewModel.toggleFilter()
                            }) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(viewModel.showFilter ? AppTheme.appPrimary : AppTheme.appTextLight)
                            }
                                                        
                            // Location status indicator
                          /*  if locationService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if locationService.authorizationStatus == .authorizedWhenInUse || 
                                        locationService.authorizationStatus == .authorizedAlways {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            } else if locationService.authorizationStatus == .denied {
                                Button("Enable Location") {
                                    // You'll need to implement openLocationSettings in LocationService
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            } */
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenPadding)
                        
                        // Filter View - appears when showFilter is true
                        if viewModel.showFilter {
                            ClimbingTypeFilterView(selectedTypes: Binding(
                                get: { viewModel.selectedFilterTypes },
                                set: { viewModel.updateFilterSelection($0) }
                            ))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        if viewModel.isLoading {
                            // Loading state
                            ForEach(0..<3, id: \.self) { _ in
                                GymCardViewSkeleton()
                                        .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
                            }
                        } else {
                            ForEach(viewModel.nonFavoriteGymsByDistance) { gym in
                                LargeGymCardView(gym: gym, viewModel: viewModel)
                                    .padding(.horizontal, AppTheme.Spacing.cardHorizontalPadding)
                            }
                        }
                    }
                }
                .padding(.bottom, AppTheme.Spacing.screenPadding) // Add bottom padding for better scroll experience
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: GymsMapView(viewModel: viewModel, selectedGymId: nil)) {
                        Image(systemName: "map")
                            .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Gyms")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
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
            .navigationDestination(isPresented: $viewModel.showGymProfile) {
                if let selectedGym = viewModel.selectedGym {
                    GymProfileView(gym: selectedGym, appState: viewModel.currentAppState)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    GymsListView(appState: AppState())
}

