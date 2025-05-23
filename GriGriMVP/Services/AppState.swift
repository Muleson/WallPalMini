//
//  AppState.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import SwiftUI

enum AuthenticationState {
    case unauthenticated
    case authenticated
    case checking
}

enum ProfileType {
    case gym
    case user
}

@MainActor
class AppState: ObservableObject {
    @Published var authState: AuthenticationState = .checking
    @Published var user: User?
    @Published var gym: Gym?
    @Published var profileType: ProfileType?
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
        self.userRepository = userRepository
        
        Task {
            await checkAuthState()
        }
    }
    
    func checkAuthState() async {
        do {
            if userRepository.getCurrentAuthUser() != nil {
                if let currentUser = try await userRepository.getCurrentUser() {
                    await MainActor.run {
                        self.user = currentUser
                        self.authState = .authenticated
                    }
                    return
                }
            }
            
            await MainActor.run {
                self.authState = .unauthenticated
            }
        } catch {
            print("Error checking auth state: \(error)")
            await MainActor.run {
                self.authState = .unauthenticated
            }
        }
    }
    
    func updateAuthState(user: User?) {
        self.user = user
        self.authState = user != nil ? .authenticated : .unauthenticated
    }
}

struct RootView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            switch appState.authState {
                case .checking:
                    ProgressView("Checking Authentication...")
                case .authenticated:
                    MainTabView(appState: appState)
                case .unauthenticated:
                    AuthContainerView(appState: appState)
            }
        }
    }
}
