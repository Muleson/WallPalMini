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
            ScrollView {
                VStack(alignment: .center, spacing: 8) {
                    // Quick action button
                    QuickActionButton()
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: 0) {
                        // Featured Events section
                        FeaturedEventsSection(viewModel: viewModel)
                        
                        // Events from Favorite Gyms section
                        FavoriteGymsEventsSection(viewModel: viewModel)
                        
                        // Nearby Events section
                        NearbyEventsSection(viewModel: viewModel)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Hello, \(appState.user?.firstName ?? "")")
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
}

#Preview {
    HomeView(appState: AppState())
}
