//
//  GymDuplicateConfirmationView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 08/08/2025.
//

import SwiftUI

struct GymDuplicateConfirmationView: View {
    @ObservedObject var viewModel: PassCreationViewModel
    let isPrimary: Bool
    let onPassSaved: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .padding(.top, 20)
                    
                    Text("Duplicate Gym Pass Found")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.appTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Display gym information
                    if let gym = viewModel.selectedGym {
                        VStack(spacing: 16) {
                            // Gym profile image
                            if let profileImage = gym.profileImage {
                                AsyncImage(url: profileImage.url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    gymImagePlaceholder
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.appPrimary.opacity(0.3), lineWidth: 2)
                                )
                            } else {
                                gymImagePlaceholder
                            }
                            
                            VStack(alignment: .center, spacing: 8) {
                                Text(gym.name)
                                    .font(.appSubheadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Explanation text
                    VStack(spacing: 12) {
                        Text("You already have a pass for this gym.")
                            .font(.appBody)
                            .foregroundColor(AppTheme.appTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        if let existingPass = viewModel.duplicateGymPassFound {
                            Text("Existing pass: \"\(existingPass.mainInformation.title)\"")
                                .font(.caption)
                                .foregroundColor(AppTheme.appTextLight)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Text("Would you like to replace the existing pass with the new one?")
                            .font(.appBody)
                            .foregroundColor(AppTheme.appTextPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Add some bottom padding
                    Color.clear.frame(height: 20)
                }
            }
            
            // Fixed bottom button area
            VStack(spacing: 0) {
                Divider()
                
                VStack(spacing: 12) {
                    Button("Replace Existing Pass") {
                        let success = viewModel.replaceExistingGymPass(primaryStatus: isPrimary)
                        
                        if success {
                            viewModel.lastSavedPassWasSuccessful = true
                            onPassSaved()
                        }
                    }
                    .font(.appButtonPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.appPrimary)
                    .foregroundColor(AppTheme.appTextButton)
                    .cornerRadius(10)
                    
                    Button("Cancel") {
                        viewModel.cancelGymDuplicateFlow()
                        onCancel()
                    }
                    .font(.appButtonSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.appContentBG)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(AppTheme.appBackgroundBG)
            }
        }
        .background(AppTheme.appBackgroundBG)
        .navigationTitle("Duplicate Pass")
        .navigationBarBackButtonHidden(true)
    }
    
    private var gymImagePlaceholder: some View {
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
}
