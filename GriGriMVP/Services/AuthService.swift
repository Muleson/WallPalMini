//
//  AuthService.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation

@MainActor
class AuthService: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false
        
    private var appState: AppState
    private let userRepository: UserRepositoryProtocol
    
    init(appState: AppState, userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
        self.appState = appState
        self.userRepository = userRepository
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await userRepository.signIn(email: email, password: password)
            
            await MainActor.run {
                appState.updateAuthState(user: user)
            }
        } catch {
            print("Detailed error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createUser(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
            
        do {
            let user = try await userRepository.createUser(
                email: email, 
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            await MainActor.run {
                appState.updateAuthState(user: user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
            
        isLoading = false
    }
    
    func signOut() {
        do {
            try userRepository.signOut()
            appState.updateAuthState(user: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
