//
//  PassesView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI

struct PassesRootView: View {
    @ObservedObject private var appState = AppState()
    @StateObject private var passViewModel = PassViewModel()
    
    @State private var scannerIsPresented: Bool = false
    @State private var gymSelectionIsPresented: Bool = false
    @State private var passToDelete: Pass? = nil
    @State private var refreshTrigger = UUID() // Used to force view refresh
    
    @State var isPrimary: Bool = false
    
    var body: some View {
        VStack {
            PrimaryPassView(viewModel: passViewModel)
                .padding()
                .id(UUID()) // This helps refresh the primary pass view
            
            List {
                ForEach(passViewModel.passes) { pass in
                    PassRowView(viewModel: passViewModel, passToDelete: $passToDelete, pass: pass)
                }
            }
            .id(refreshTrigger) // This helps refresh the list when passes change
            .confirmationDialog("Delete Pass?",
                                isPresented: .init(
                                    get: { if case .confirming = passViewModel.deletionState { return true }; return false },
                                    set: { if !$0 { passViewModel.cancelDelete() }}
                                )
            ) {
                if case let .confirming(pass) = passViewModel.deletionState {
                    Button("Delete", role: .destructive) {
                        passViewModel.handleDelete(for: pass)
                    }
                    Button("Cancel", role: .cancel) {
                        passViewModel.cancelDelete()
                    }
                }
            } message: {
                if case let .confirming(pass) = passViewModel.deletionState {
                    Text(pass.deletionMessage)
                }
            }
            .navigationTitle("Passes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        gymSelectionIsPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .foregroundStyle(AppTheme.appAccent)
                }
            }
            .sheet(isPresented: $gymSelectionIsPresented) {
                NavigationStack {
                    GymSelectionView(passViewModel: passViewModel, isPrimary: $isPrimary,isPresented: $gymSelectionIsPresented)
                    }
            }
            .onAppear {
                refreshPasses()
            }
            .onChange(of: scannerIsPresented) {_, newValue in
                if !newValue {
                    // When scanner sheet is dismissed, refresh passes
                    refreshPasses()
                }
            }
        }
    }
    
    private func refreshPasses() {
        passViewModel.loadPasses()
        refreshTrigger = UUID() // Force view refresh
        
        // Debug output
        print("PassesView refreshed. Passes count: \(passViewModel.passes.count)")
        print("Primary pass exists: \(passViewModel.primaryPass != nil)")
    }
}
