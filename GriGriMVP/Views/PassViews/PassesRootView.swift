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
        Group {
            if displayViewModel.allPasses.isEmpty {
                // Empty state view
                emptyStateView
            } else {
                // Use unified List for smooth scrolling and swipe actions
                List {
                    // Primary pass section
                    Section {
                        VStack(spacing: 0) {
                            PrimaryPassView(displayViewModel: displayViewModel)
                                .padding(.top, 16)
                            
                            // Divider between barcode view and passes list
                            Divider()
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                                .padding(.bottom, 4)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    
                    // All Passes section
                    Section {
                        ForEach(displayViewModel.allPasses) { pass in
                            PassRowView(
                                viewModel: displayViewModel,
                                pass: pass
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        
                        // Bottom spacing for floating button
                        Color.clear
                            .frame(height: 100)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    } header: {
                        HStack {
                            Text("All Passes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.appTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                        .background(AppTheme.appBackgroundBG)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(AppTheme.appBackgroundBG)
                .overlay(alignment: .bottom) {
                    // Floating Add Pass Button
                    PrimaryActionButton.primary("Add Pass") {
                        showPassCreation = true
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .alert("Delete Pass?", 
               isPresented: .init(
                   get: { if case .confirming = displayViewModel.deletionState { return true }; return false },
                   set: { if !$0 { displayViewModel.cancelDelete() }}
               )) {
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
        .navigationBarTitleDisplayMode(.large)
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
