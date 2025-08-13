//
//  PassCreationFlowView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 03/08/2025.
//

import Foundation
import SwiftUI

struct PassCreationFlowView: View {
    @StateObject private var creationViewModel = PassCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onPassAdded: () -> Void
    let onCancel: (() -> Void)?
    
    var body: some View {
        GymSelectionView(
            viewModel: creationViewModel,
            onPassAdded: { [weak creationViewModel] in
                // Verify the pass was actually saved before calling success
                guard let viewModel = creationViewModel,
                      viewModel.lastSavedPassWasSuccessful else {
                    return
                }
                
                // Call the completion handler
                onPassAdded()
                
                // Dismiss after a small delay to ensure UserDefaults sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            },
            onCancel: {
                // Handle cancellation by calling the cancel callback if provided
                onCancel?()
            }
        )
        .navigationBarBackButtonHidden(false) // Allow back navigation
    }
}
