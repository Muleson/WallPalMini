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
    
    // Create AuthService instance with appState
    @StateObject private var authService: AuthService
    
    // Add close action for better UX
    let onClose: () -> Void
    
    init(appState: AppState, onClose: @escaping () -> Void = {}) {
        self.appState = appState
        self.onClose = onClose
        self._authService = StateObject(wrappedValue: AuthService(appState: appState))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // User Profile Section
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(appState.user?.firstName ?? "") \(appState.user?.lastName ?? "")")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Profile")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 92) // Account for status bar, navigation bar, and additional 32px spacing
                
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
                .padding(.top, 40) // Increased spacing after removing divider
                
                Divider()
                    .frame(height: 1)
                    .background(.white.opacity(0.3))
                    .padding(.horizontal, 12)
                    .padding(.top, 20)
                
                // Support Section
                VStack(spacing: 16) {
                    MenuButton(title: "Get in Touch", action: {
                        // TODO: Navigate to contact/support
                    })
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                Divider()
                    .frame(height: 1)
                    .background(.white.opacity(0.3))
                    .padding(.horizontal, 12)
                    .padding(.top, 20)
                
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
                .padding(.top, 20)
                
                // Push content up, leaving space for tab bar
                Spacer()
                
                // Bottom padding to account for tab bar
                Color.clear
                    .frame(height: 100)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppTheme.appPrimary,
                        AppTheme.appPrimary.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Close button positioned at bottom right
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120) // Account for tab bar plus some extra spacing
                }
            }
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
    MenuBarView(appState: AppState(), onClose: {})
}