//
//  GymVerificationConfirmationView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/08/2025.
//

import SwiftUI

struct GymVerificationConfirmationView: View {
    let gymName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.appPrimary)
                
                // Main Content
                VStack(spacing: 16) {
                    Text("Gym Registered Successfully!")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.appTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("\"\(gymName)\" has been submitted for verification.")
                        .font(.appSubheadline)
                        .foregroundColor(AppTheme.appTextPrimary)
                        .multilineTextAlignment(.center)
                }
                
                // Information Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.appPrimary)
                            .font(.title3)
                        
                        Text("What happens next?")
                            .font(.appSubheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.appTextPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VerificationStepView(
                            step: "1",
                            title: "Review Process",
                            description: "Our team will review your gym details."
                        )
                        
                        VerificationStepView(
                            step: "2",
                            title: "Contact & Onboarding",
                            description: "We'll be in touch to confirm your addition and ensure you will get the most out of Crahg."
                        )
                        
                        VerificationStepView(
                            step: "3",
                            title: "Go Live",
                            description: "Once verified, your gym will be live in the app and accessible to the whole Crahg community."
                        )
                    }
                }
                .padding(20)
                .background(AppTheme.appContentBG)
                .cornerRadius(16)
                
                Spacer()
                
                // Action Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Continue")
                        .font(.appButtonPrimary)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.appPrimary)
                        .cornerRadius(15)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .background(AppTheme.appBackgroundBG)
            .navigationBarHidden(true)
        }
    }
}

struct VerificationStepView: View {
    let step: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step Number
            ZStack {
                Circle()
                    .fill(AppTheme.appPrimary.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Text(step)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.appPrimary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.appTextPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.appTextLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    GymVerificationConfirmationView(gymName: "Test Climbing Gym")
}
