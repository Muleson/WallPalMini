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
                VStack(spacing: 24) {
                    // Favourites Section - only show if there are favorite gyms
                    if !viewModel.favoriteGyms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Favourites")
                                    .font(.appHeadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                    .padding(.horizontal, 16)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.favoriteGyms) { gym in
                                        CompactGymCard(gym: gym, viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    // Discover Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Discover")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                                .padding(.horizontal, 16)
                            Spacer()
                            
                            // Location status indicator
                            if locationService.isLoading {
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
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        if viewModel.isLoading {
                            // Loading state
                            ForEach(0..<3, id: \.self) { _ in
                                GymCardViewSkeleton()
                                    .padding(.horizontal, 16)
                            }
                        } else {
                            ForEach(viewModel.nonFavoriteGymsByDistance) { gym in
                                LargeGymCardView(gym: gym, viewModel: viewModel)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: GymsMapView(viewModel: viewModel)) {
                        Image(systemName: "map")
                            .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
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
                    GymProfileView(gym: selectedGym)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private func gymCardView(for gym: Gym) -> some View {
        GymCardView(
            gym: gym,
            events: viewModel.eventsForGym(gym.id),
            viewModel: viewModel
        )
    }
}

#Preview {
    GymsListView(appState: AppState())
}

