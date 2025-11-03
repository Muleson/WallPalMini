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
    @State private var navigateToSavedEvents = false
    @State private var navigateToYourClasses = false

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
        NavigationStack {
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
                VStack(spacing: 8) {
                    MenuButton(title: "Saved Events", action: {
                        navigateToSavedEvents = true
                        onClose()
                    })

                    MenuButton(title: "Your Classes", action: {
                        navigateToYourClasses = true
                        onClose()
                    })

                    MenuButton(title: "Settings", action: {
                        // TODO: Navigate to settings
                    })
                }
                .padding(.horizontal, 16)
                .padding(.top, 40) // Increased spacing after removing divider
            
            Divider()
                .frame(height: 0.5)
                .background(.white.opacity(0.2))
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            // Support Section
            VStack(spacing: 8) {
                MenuButton(title: "Get in Touch", action: {
                    // TODO: Navigate to contact/support
                })
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            
            Divider()
                .frame(height: 0.5)
                .background(.white.opacity(0.2))
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            // Account Section
            VStack(spacing: 8) {
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
                ZStack {
                    // Base translucent background with subtle gradient
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: AppTheme.appPrimary.opacity(0.85), location: 0.0),
                            .init(color: AppTheme.appPrimary.opacity(0.75), location: 0.3),
                            .init(color: AppTheme.appPrimary.opacity(0.8), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Subtle overlay for depth
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.3))
                }
            )
            .background(.ultraThinMaterial)
            .navigationDestination(isPresented: $navigateToSavedEvents) {
                SavedEventsView()
            }
            .navigationDestination(isPresented: $navigateToYourClasses) {
                SavedClassesView()
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
}

// MARK: - Menu Button Component
private struct MenuButton: View {
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback for modern iOS feel
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Subtle chevron for better affordance
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isPressed ? 0.15 : 0.08))
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Liquid Button Style
private struct LiquidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
    }
}

#Preview {
    MenuBarView(appState: AppState(), onClose: {})
}