//
//  AuthContainerView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/05/2025.
//

import Foundation
import SwiftUI
import AuthenticationServices

struct AuthContainerView: View {
    @ObservedObject var appState: AppState
    @State private var showSignUp = false
    
    var body: some View {
        SignInView(appState: appState)
            .sheet(isPresented: $showSignUp) {
                SignUpView(appState: appState)
            }
    }
}

struct SignUpView: View {
    @StateObject private var viewModel: AuthService
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    init(appState: AppState) {
         _viewModel = StateObject(wrappedValue: AuthService(appState: appState))
         self.appState = appState
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo Section
                    VStack(spacing: 16) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        
                        Text("Join Crahg")
                            .font(.appHeadline)
                            .foregroundColor(AppTheme.appTextPrimary)
                    }
                    .padding(.top, 40)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            CustomTextField(title: "First Name", text: $firstName)
                            CustomTextField(title: "Last Name", text: $lastName)
                            CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                            CustomSecureField(title: "Password", text: $password)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.appBody)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Create Account Button
                        Button {
                            Task {
                                await viewModel.createUser(
                                    email: email,
                                    password: password,
                                    firstName: firstName,
                                    lastName: lastName
                                )
                                if appState.user != nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(AppTheme.appTextButton)
                                } else {
                                    Text("Create Account")
                                        .font(.appButtonPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.appPrimary)
                            .foregroundColor(AppTheme.appTextButton)
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading || !isFormValid)
                        .opacity((!isFormValid || viewModel.isLoading) ? 0.6 : 1.0)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppTheme.appTextLight.opacity(0.3))
                            Text("or")
                                .font(.appBody)
                                .foregroundColor(AppTheme.appTextLight)
                                .padding(.horizontal, 16)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppTheme.appTextLight.opacity(0.3))
                        }
                        
                        // Apple Sign In Button
                        Button {
                            Task {
                                await viewModel.signInWithApple()
                                if appState.user != nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Sign up with Apple")
                                        .font(.appButtonPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(AppTheme.appBackgroundBG)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.appPrimary)
                    .font(.appButtonSecondary)
                }
            }
        }
    }
    
    // Form validation
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty &&
        password.count >= 6 && email.contains("@")
    }
}

struct SignInView: View {
    @StateObject private var viewModel: AuthService
    @ObservedObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpPresented = false
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: AuthService(appState: appState))
        self.appState = appState
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    // Logo and Welcome Section
                    VStack(spacing: 24) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                        
                        VStack(spacing: 8) {
                            Text("Welcome to Crahg")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                            
                            Text("Your climbing community awaits")
                                .font(.appSubheadline)
                                .foregroundColor(AppTheme.appTextLight)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Sign In Section
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                            CustomSecureField(title: "Password", text: $password)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.appBody)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Sign In Button
                        Button {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(AppTheme.appTextButton)
                                } else {
                                    Text("Sign In")
                                        .font(.appButtonPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.appPrimary)
                            .foregroundColor(AppTheme.appTextButton)
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading || !isFormValid)
                        .opacity((!isFormValid || viewModel.isLoading) ? 0.6 : 1.0)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppTheme.appTextLight.opacity(0.3))
                            Text("or")
                                .font(.appBody)
                                .foregroundColor(AppTheme.appTextLight)
                                .padding(.horizontal, 16)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppTheme.appTextLight.opacity(0.3))
                        }
                        
                        // Apple Sign In Button
                        Button {
                            Task {
                                await viewModel.signInWithApple()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Sign in with Apple")
                                        .font(.appButtonPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        
                        // Create Account Button
                        Button("Don't have an account? Sign up") {
                            isSignUpPresented = true
                        }
                        .font(.appButtonSecondary)
                        .foregroundColor(AppTheme.appPrimary)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(AppTheme.appBackgroundBG)
        }
        .sheet(isPresented: $isSignUpPresented) {
            SignUpView(appState: appState)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@") && email.contains(".")
    }
}

// MARK: - Custom Components
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appUnderline)
                .foregroundColor(AppTheme.appTextPrimary)
            
            TextField("", text: $text)
                .textFieldStyle(CustomTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appUnderline)
                .foregroundColor(AppTheme.appTextPrimary)
            
            SecureField("", text: $text)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppTheme.appContentBG)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.appTextLight.opacity(0.2), lineWidth: 1)
            )
            .font(.appBody)
            .foregroundColor(AppTheme.appTextPrimary)
    }
}

// MARK: - Previews
#Preview("Sign In View") {
    SignInView(appState: AppState())
}

#Preview("Sign Up View") {
    SignUpView(appState: AppState())
}

#Preview("Auth Container") {
    AuthContainerView(appState: AppState())
}
