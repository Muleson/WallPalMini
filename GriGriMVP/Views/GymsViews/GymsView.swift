//
//  GymsView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/06/2025.
//

import SwiftUI

struct GymsView: View {
    @StateObject private var viewModel: GymsViewModel
    @ObservedObject private var locationService = LocationService.shared
    
    init(
        gymRepository: GymRepositoryProtocol = FirebaseGymRepository(),
        eventRepository: EventRepositoryProtocol = FirebaseEventRepository(),
        appState: AppState
    ) {
        self._viewModel = StateObject(wrappedValue: GymsViewModel(
            gymRepository: gymRepository,
            eventRepository: eventRepository,
            appState: appState
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Favourite Gyms Section
                    if !viewModel.favoriteGyms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Favourite Gyms")
                                    .font(.appHeadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            ForEach(viewModel.favoriteGyms) { gym in
                                GymCardView(
                                    gym: gym,
                                    events: viewModel.eventsForGym(gym.id),
                                    viewModel: viewModel
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Divider
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    
                    // All Gyms Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(viewModel.favoriteGyms.isEmpty ? "Gyms Near You" : "More Gyms")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
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
                                gymCardView(for: gym)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
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
    GymsView(
        gymRepository: SampleData.MockGymRepository(),
        eventRepository: SampleData.MockEventRepository(),
        appState: AppState()
    )
}

