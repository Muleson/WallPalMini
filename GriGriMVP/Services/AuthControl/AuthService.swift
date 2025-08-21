//
//  AuthService.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import AuthenticationServices

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
    
    func signInWithApple() async {
        guard !isLoading else { 
            print("DEBUG: Apple Sign In already in progress, ignoring call")
            return 
        }
        
        isLoading = true
        errorMessage = nil
        
        print("DEBUG: Starting Apple Sign In process")
        
        do {
            print("DEBUG: Calling AppleSignInManager.shared.signInWithApple()")
            let appleData = try await AppleSignInManager.shared.signInWithApple()
            
            print("DEBUG: Apple Sign In successful, calling userRepository.signInWithApple")
            let user = try await userRepository.signInWithApple(
                idToken: appleData.idToken,
                nonce: appleData.nonce,
                fullName: appleData.fullName
            )
            
            print("DEBUG: Firebase authentication successful")
            await MainActor.run {
                appState.updateAuthState(user: user)
                isLoading = false
                
                // Check if profile completion is needed (if this function exists)
                // checkForProfileCompletion(user: user)
            }
            
        } catch {
            print("DEBUG: Apple Sign In error: \(error)")
            print("DEBUG: Error type: \(type(of: error))")
            
            await MainActor.run {
                // Only show error message if it's not a user cancellation
                if let authError = error as? ASAuthorizationError {
                    switch authError.code {
                    case .canceled:
                        print("DEBUG: User canceled Apple Sign In - not showing error message")
                        // Don't show error message for cancellation
                        break
                    case .failed:
                        errorMessage = "Apple Sign In failed. Please check your Apple ID configuration."
                    case .invalidResponse:
                        errorMessage = "Invalid response from Apple. Please try again."
                    case .notHandled:
                        errorMessage = "Apple Sign In not handled properly. Please contact support."
                    case .unknown:
                        errorMessage = "Unknown error occurred during Apple Sign In"
                    @unknown default:
                        errorMessage = "An unexpected error occurred"
                    }
                } else if let appleSignInError = error as? AppleSignInError {
                    switch appleSignInError {
                    case .invalidState:
                        errorMessage = "Invalid sign in state. Please try again."
                    case .noIdentityToken:
                        errorMessage = "Unable to get identity token from Apple"
                    case .tokenSerializationFailed:
                        errorMessage = "Failed to process Apple credentials"
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}
