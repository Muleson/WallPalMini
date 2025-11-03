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
    @Published var deepLinkManager = DeepLinkManager()

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository()) {
        self.userRepository = userRepository

        Task { [weak self] in
            guard let self = self else { return }
            await checkAuthState()
        }
    }
    
    func checkAuthState() async {
        do {
            if userRepository.getCurrentAuthUser() != nil {
                if let currentUser = try await userRepository.getCurrentUser() {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.user = currentUser
                        self.authState = .authenticated
                    }
                    return
                }
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.authState = .unauthenticated
            }
        } catch {
            print("Error checking auth state: \(error)")
            await MainActor.run { [weak self] in
                guard let self = self else { return }
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
                    VStack {
                        Image("AppLogoNegative")
                            .resizable()
                            .frame(width: 196, height: 196)
                            .padding(.bottom, 32)
                        ProgressView()
                            .frame(width: 32, height: 32)
                            .scaleEffect(1.0)
                            .tint(AppTheme.appBackgroundBG)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.appPrimary)
                case .authenticated:
                    MainTabView(appState: appState)
                case .unauthenticated:
                    AuthContainerView(appState: appState)
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        if let destination = appState.deepLinkManager.handleURL(url) {
            appState.deepLinkManager.setPendingDeepLink(destination)
        }
    }
}
