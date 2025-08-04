//
//  PassDetailView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/04/2025.
//

import SwiftUI

struct PassConfirmationView: View {
    @ObservedObject var viewModel: PassCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    // We'll directly use the primary status from GymSelectionView
    var isPrimary: Bool
    var onPassSaved: () -> Void
        
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.appPrimary)
                .padding(.top, 20)
            
            Text("Scan successful!")
                .font(.appHeadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.appTextPrimary)
            
            // Display the gym details
            if let gym = viewModel.selectedGym {
                VStack(spacing: 16) {
                    // Gym profile image
                    if let profileImage = gym.profileImage {
                        AsyncImage(url: profileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.appContentBG)
                                .overlay(
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppTheme.appTextLight)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.appPrimary.opacity(0.3), lineWidth: 2)
                        )
                    } else {
                        // Fallback when no profile image
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.appContentBG)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.appTextLight)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.appPrimary.opacity(0.3), lineWidth: 2)
                            )
                    }
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text("Gym")
                            .font(.appUnderline)
                            .foregroundColor(AppTheme.appTextLight)
                        
                        Text(gym.name)
                            .font(.appSubheadline)
                            .foregroundColor(AppTheme.appTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Show primary status with improved styling
                        HStack(spacing: 4) {
                            Image(systemName: isPrimary ? "star.fill" : "star")
                                .foregroundColor(isPrimary ? AppTheme.appPrimary : AppTheme.appTextLight)
                                .font(.system(size: 14))
                            
                            Text(isPrimary ? "Primary pass" : "Secondary pass")
                                .font(.appBody)
                                .foregroundColor(isPrimary ? AppTheme.appPrimary : AppTheme.appTextLight)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isPrimary ? AppTheme.appPrimary.opacity(0.1) : AppTheme.appContentBG)
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    viewModel.lastScannedPass = nil
                    // This will go back one level in navigation stack
                    dismiss()
                }
                .font(.appButtonSecondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.appContentBG)
                .foregroundColor(AppTheme.appTextPrimary)
                .cornerRadius(10)
                
                Button("Save") {
                    let success = viewModel.savePassWithGym(primaryStatus: isPrimary)
                    
                    if success {
                        // Mark success and trigger callback
                        viewModel.lastSavedPassWasSuccessful = true
                        onPassSaved()
                        
                        // Let the callback chain handle dismissal
                        // Don't dismiss here - let PassCreationFlowView handle it
                    }
                }
                .font(.appButtonPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.appPrimary)
                .foregroundColor(AppTheme.appTextButton)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(AppTheme.appBackgroundBG)
        .navigationTitle("Pass Details")
        .navigationBarBackButtonHidden(true)
        .alert("Duplicate Pass", isPresented: $viewModel.duplicatePassAlert) {
            Button("OK", role: .cancel) {
                // Go back to previous view, don't dismiss entire flow
                dismiss()
            }
        } message: {
            Text("This pass has already been added as '\(viewModel.duplicatePassName)'")
        }
    }
}

#Preview {
    PassConfirmationView(
        viewModel: PassCreationViewModel(),
        isPrimary: true,
        onPassSaved: {}
    )
}
