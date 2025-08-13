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
    var onCancel: () -> Void
    
    // Computed property to check if pass type is selected
    private var isPassTypeSelected: Bool {
        return viewModel.hasSelectedPassType
    }
        
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
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
                                Text(gym.name)
                                    .font(.appSubheadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Pass Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pass Type")
                                .font(.appSubheadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(PassType.allCases, id: \.self) { passType in
                                    PassTypeSelectionButton(
                                        passType: passType,
                                        isSelected: viewModel.selectedPassType == passType,
                                        onTap: {
                                            viewModel.selectedPassType = passType
                                            viewModel.hasSelectedPassType = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Validation message
                        if !isPassTypeSelected {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text("Please select a pass type to continue")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    
                    // Add some bottom padding to ensure content doesn't get cut off
                    Color.clear.frame(height: 20)
                }
            }
            
            // Fixed bottom button area
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        viewModel.lastScannedPass = nil
                        // Use the callback to navigate back to PassRootView
                        onCancel()
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
                    .background(isPassTypeSelected ? AppTheme.appPrimary : Color.gray)
                    .foregroundColor(AppTheme.appTextButton)
                    .cornerRadius(10)
                    .disabled(!isPassTypeSelected)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(AppTheme.appBackgroundBG)
            }
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
        .navigationDestination(isPresented: $viewModel.showGymDuplicateConfirmation) {
            GymDuplicateConfirmationView(
                viewModel: viewModel,
                isPrimary: isPrimary,
                onPassSaved: onPassSaved,
                onCancel: onCancel
            )
        }
    }
}

// MARK: - PassTypeSelectionButton
struct PassTypeSelectionButton: View {
    let passType: PassType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: 12) {
                    // Icon for each pass type
                    Image(systemName: iconForPassType(passType))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : AppTheme.appPrimary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(passType.rawValue)
                            .font(.appBody)
                            .foregroundColor(isSelected ? .white : AppTheme.appTextPrimary)
                        
                        Text(descriptionForPassType(passType))
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.appTextLight)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : AppTheme.appTextLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundView)
            .overlay(overlayView)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? AppTheme.appPrimary : AppTheme.appContentBG)
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? AppTheme.appPrimary : Color.clear, lineWidth: 2)
    }
    
    // Helper functions for pass type UI
    private func iconForPassType(_ passType: PassType) -> String {
        switch passType {
        case .payAsYouGo:
            return "creditcard"
        case .membership:
            return "crown"
        case .punchCard:
            return "rectangle.grid.3x2"
        }
    }
    
    private func descriptionForPassType(_ passType: PassType) -> String {
        switch passType {
        case .payAsYouGo:
            return "Pay for each visit"
        case .membership:
            return "Unlimited access"
        case .punchCard:
            return "Pre-paid visits"
        }
    }
}

// MARK: - PassConfirmationView Extension
extension PassConfirmationView {
    // Helper functions for pass type UI
    private func iconForPassType(_ passType: PassType) -> String {
        switch passType {
        case .payAsYouGo:
            return "creditcard"
        case .membership:
            return "crown"
        case .punchCard:
            return "rectangle.grid.3x2"
        }
    }
    
    private func descriptionForPassType(_ passType: PassType) -> String {
        switch passType {
        case .payAsYouGo:
            return "Pay for each visit"
        case .membership:
            return "Unlimited access"
        case .punchCard:
            return "Pre-paid visits"
        }
    }
}

#Preview {
    PassConfirmationView(
        viewModel: PassCreationViewModel(),
        isPrimary: true,
        onPassSaved: {},
        onCancel: {}
    )
}
