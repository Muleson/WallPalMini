//
//  PassesView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI

struct PassesRootView: View {
    @ObservedObject var appState: AppState
    
    @StateObject private var displayViewModel = PassDisplayViewModel()
    @State private var showPassCreation = false
    
    var body: some View {
        ZStack {
            VStack {
                if displayViewModel.allPasses.isEmpty {
                    // Empty state view
                    emptyStateView
                } else {
                    // Show primary pass at the top
                    PrimaryPassView(viewModel: displayViewModel)
                        .padding()
                    
                    // Show ALL passes in the list, including the active one
                    List {
                        ForEach(displayViewModel.allPasses) { pass in
                            PassRowView(
                                viewModel: displayViewModel, 
                                passToDelete: .constant(nil),
                                pass: pass
                            )
                        }
                    }
                }
            }
            
            // Floating Add Pass Button - only show when user has passes
            if !displayViewModel.allPasses.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        PrimaryActionButton.primary("Add Pass") {
                            showPassCreation = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .confirmationDialog("Delete Pass?",
                            isPresented: .init(
                                get: { if case .confirming = displayViewModel.deletionState { return true }; return false },
                                set: { if !$0 { displayViewModel.cancelDelete() }}
                            )
        ) {
            if case let .confirming(pass) = displayViewModel.deletionState {
                Button("Delete", role: .destructive) {
                    displayViewModel.handleDelete(for: pass)
                }
                Button("Cancel", role: .cancel) {
                    displayViewModel.cancelDelete()
                }
            }
        } message: {
            if case let .confirming(pass) = displayViewModel.deletionState {
                Text(pass.deletionMessage)
            }
        }
        .navigationTitle("Passes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showPassCreation = true
                }) {
                    Image(systemName: "plus")
                }
                .foregroundStyle(AppTheme.appPrimary)
            }
        }
        .navigationDestination(isPresented: $showPassCreation) {
            PassCreationFlowView(
                onPassAdded: {
                    showPassCreation = false
                },
                onCancel: {
                    showPassCreation = false
                }
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "ticket.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.appPrimary)
                .padding(.bottom, 10)
            
            Text("No Passes Added Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add your gym passes to easily check in and keep all your passes in one place, without any pesky plastic!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            PrimaryActionButton.primary("Add Your First Pass") {
                showPassCreation = true
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
}

#Preview("With Passes") {
    NavigationStack {
        PassesRootView(appState: AppState())
    }
}

#Preview("Empty State") {
    NavigationStack {
        PassesRootView(appState: AppState())
    }
}
