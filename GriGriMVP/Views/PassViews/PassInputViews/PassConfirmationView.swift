//
//  PassDetailView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/04/2025.
//

import SwiftUI

struct PassConfirmationView: View {
    @ObservedObject var passViewModel: PassViewModel
    @Binding var dismissToRoot: Bool
    
    // We'll directly use the primary status from GymSelectionView
    var isPrimary: Bool
    var onPassSaved: () -> Void
        
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.top, 20)
            
            Text("Scan successful!")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Display the gym details
            if let gym = passViewModel.selectedGym {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gym")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(gym.name)
                        .font(.title3)
                        .padding(.bottom, 8)
                    
                    // Show primary status but don't allow changing
                    HStack {
                        Text("Primary pass:")
                        Text(isPrimary ? "Yes" : "No")
                            .fontWeight(.medium)
                            .foregroundColor(isPrimary ? .blue : .secondary)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    passViewModel.lastScannedPass = nil
                    dismissToRoot = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(10)
                
                Button("Save") {
                    // Save with primary status passed from GymSelectionView
                    let success = passViewModel.savePassWithGym(primaryStatus: isPrimary)
                    
                    if success {
                        onPassSaved()
                        dismissToRoot = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .navigationTitle("Pass Details")
        .navigationBarBackButtonHidden(true)
        .alert("Duplicate Pass", isPresented: $passViewModel.duplicatePassAlert) {
            Button("OK", role: .cancel) {
                dismissToRoot = true
            }
        } message: {
            Text("This pass has already been added as '\(passViewModel.duplicatePassName)'")
        }
    }
}

#Preview {
    PassConfirmationView(
        passViewModel: PassViewModel(),
        dismissToRoot: .constant(false),
        isPrimary: true,
        onPassSaved: {}
    )
}
