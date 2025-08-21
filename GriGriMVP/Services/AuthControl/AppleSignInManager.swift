//
//  AppleSignInManager.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/08/2025.
//

import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
class AppleSignInManager: NSObject, ObservableObject {
    static let shared = AppleSignInManager()
    
    // Unhashed nonce for security
    private var currentNonce: String?
    
    // Completion handler for sign-in flow
    private var signInCompletion: ((Result<(idToken: String, nonce: String, fullName: PersonNameComponents?), Error>) -> Void)?
    
    // Prevent multiple concurrent sign-in attempts
    private var isSignInInProgress = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    func signInWithApple() async throws -> (idToken: String, nonce: String, fullName: PersonNameComponents?) {
        guard !isSignInInProgress else {
            print("DEBUG: Apple Sign In already in progress")
            throw AppleSignInError.invalidState
        }
        
        isSignInInProgress = true
        
        return try await withCheckedThrowingContinuation { continuation in
            signInCompletion = { result in
                self.isSignInInProgress = false
                continuation.resume(with: result)
            }
            
            startSignInWithAppleFlow()
        }
    }
    
    // MARK: - Private Methods
    
    private func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        // Add some debug logging
        print("DEBUG: Starting Apple Sign In flow with nonce: \(nonce)")
        print("DEBUG: SHA256 nonce: \(sha256(nonce))")
        
        // Small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            authorizationController.performRequests()
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("DEBUG: Apple Sign In authorization completed")
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print("DEBUG: Received Apple ID credential")
            print("DEBUG: User identifier: \(appleIDCredential.user)")
            print("DEBUG: Email: \(appleIDCredential.email ?? "nil")")
            print("DEBUG: Full name: \(appleIDCredential.fullName?.description ?? "nil")")
            
            guard let nonce = currentNonce else {
                print("DEBUG: Current nonce is nil")
                signInCompletion?(.failure(AppleSignInError.invalidState))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("DEBUG: Identity token is nil")
                signInCompletion?(.failure(AppleSignInError.noIdentityToken))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("DEBUG: Failed to convert identity token to string")
                signInCompletion?(.failure(AppleSignInError.tokenSerializationFailed))
                return
            }
            
            print("DEBUG: Successfully processed Apple Sign In credential")
            let result = (idToken: idTokenString, nonce: nonce, fullName: appleIDCredential.fullName)
            signInCompletion?(.success(result))
        } else {
            print("DEBUG: Authorization credential is not ASAuthorizationAppleIDCredential")
            signInCompletion?(.failure(AppleSignInError.invalidState))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("DEBUG: Apple Sign In failed with error: \(error)")
        print("DEBUG: Error domain: \(error._domain)")
        print("DEBUG: Error code: \(error._code)")
        print("DEBUG: Error description: \(error.localizedDescription)")
        
        // Reset the progress flag
        isSignInInProgress = false
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("DEBUG: User canceled Apple Sign In")
            case .failed:
                print("DEBUG: Apple Sign In failed")
            case .invalidResponse:
                print("DEBUG: Invalid response from Apple Sign In")
            case .notHandled:
                print("DEBUG: Apple Sign In not handled")
            case .unknown:
                print("DEBUG: Unknown Apple Sign In error")
            @unknown default:
                print("DEBUG: Unknown Apple Sign In error case")
            }
        }
        
        signInCompletion?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Apple Sign In Errors
enum AppleSignInError: LocalizedError {
    case invalidState
    case noIdentityToken
    case tokenSerializationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidState:
            return "Invalid state: A login callback was received, but no login request was sent."
        case .noIdentityToken:
            return "Unable to fetch identity token"
        case .tokenSerializationFailed:
            return "Unable to serialize token string from data"
        }
    }
}
