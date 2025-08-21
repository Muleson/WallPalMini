//
//  MenuBarView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/08/2025.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    
    @State private var showLogoutConfirmation = false
    @State private var navigateToGymCreation = false
    
    // Create AuthService instance with appState
    @StateObject private var authService: AuthService
    
    init(appState: AppState) {
        self.appState = appState
        self._authService = StateObject(wrappedValue: AuthService(appState: appState))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // User Profile Section
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("\(appState.user?.firstName ?? "") \(appState.user?.lastName ?? "")")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
                .frame(height: 1)
                .background(.white)
                .padding(.horizontal, 12)
            
            // Main Menu Items
            VStack(spacing: 16) {
                MenuButton(title: "Saved Events", action: {
                    // TODO: Navigate to saved events
                })
                
                MenuButton(title: "Your Classes", action: {
                    // TODO: Navigate to user classes
                })
                
                MenuButton(title: "Settings", action: {
                    // TODO: Navigate to settings
                })
            }
            .padding(.horizontal, 16)
            
            Divider()
                .frame(height: 1)
                .background(.white)
                .padding(.horizontal, 12)
            
            // Support & Gym Section
            VStack(spacing: 16) {
                MenuButton(title: "Get in Touch", action: {
                    // TODO: Navigate to contact/support
                })
                
                MenuButton(title: "Add Your Gym", action: {
                    navigateToGymCreation = true
                })
            }
            .padding(.horizontal, 16)
            
            Divider()
                .frame(height: 1)
                .background(.white)
                .padding(.horizontal, 12)
            
            // Account Section
            VStack(spacing: 16) {
                MenuButton(title: "About", action: {
                    // TODO: Navigate to about page
                })
                
                MenuButton(title: "Log Out", action: {
                    showLogoutConfirmation = true
                })
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            
            Spacer()
        }
        .background(AppTheme.appPrimary)
        .navigationDestination(isPresented: $navigateToGymCreation) {
            GymCreationView()
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// MARK: - Menu Button Component
private struct MenuButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MenuBarView(appState: AppState())
}

