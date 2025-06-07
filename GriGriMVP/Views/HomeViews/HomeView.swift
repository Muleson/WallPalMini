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
                VStack(alignment: .center) {
                    // Personalized greeting
                    HStack {
                        Text("Hello, \(appState.user?.firstName ?? "")")
                            .font(.appHeadline)
                            .foregroundColor(AppTheme.appTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
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
            .background(Color(AppTheme.appBackgroundBG))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: -8,) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .foregroundStyle(AppTheme.appPrimary)
                        
                        Text("WallPal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(AppTheme.appBackgroundBG), for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 1)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
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
