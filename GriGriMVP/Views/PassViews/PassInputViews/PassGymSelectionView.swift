//
//  TitleInputView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 29/03/2025.
//

import SwiftUI

struct GymSelectionView: View {
    @ObservedObject var passViewModel: PassViewModel
    @Binding var isPrimary: Bool
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var showScanner: Bool = false
    @State private var debounceTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search gyms", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { _, newValue in
                            // Debounce search
                            debounceTimer?.invalidate()
                            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                passViewModel.searchGyms(query: newValue)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            passViewModel.loadGyms() // Reset to all gyms
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                Text("Select your gym")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Show loading state or error
                if passViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading gyms...")
                    Spacer()
                } else if let error = passViewModel.searchError {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                    Button("Try Again") {
                        passViewModel.loadGyms()
                    }
                    .padding()
                    Spacer()
                } else if passViewModel.gyms.isEmpty {
                    Spacer()
                    Text("No gyms found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    // List of gyms
                    List {
                        ForEach(passViewModel.gyms) { gym in
                            GymRow(
                                gym: gym,
                                isSelected: gym.id == passViewModel.selectedGym?.id
                            )
                            .onTapGesture {
                                // Select this gym when tapped
                                passViewModel.selectedGym = gym
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Primary pass toggle
                Toggle("Set as primary pass", isOn: $isPrimary)
                    .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        if let gym = passViewModel.selectedGym {
                            passViewModel.prepareForScan(with: gym)
                            showScanner = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Scan Pass")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(passViewModel.selectedGym == nil ? Color.gray : AppTheme.appPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .opacity(passViewModel.selectedGym == nil ? 0.6 : 1.0)
                    }
                    .disabled(passViewModel.selectedGym == nil)
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                // Initial data load
                passViewModel.loadGyms()
            }
            .navigationBarTitle("Add New Pass", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            })
            .sheet(isPresented: $showScanner) {
                PassScannerView(
                    passViewModel: passViewModel,
                    isPrimary: isPrimary,
                    onPassAdded: {
                        isPresented = false
                    }
                )
            }
        }
    }
}

// GymRow helper view
struct GymRow: View {
    let gym: Gym
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(gym.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview("Gym Selection - With Selected") {
    GymSelectionView(
        passViewModel: createPreviewViewModel(),
        isPrimary: .constant(true),
        isPresented: .constant(true)
    )
}

#Preview("No Gym Selected") {
    GymSelectionView(
        passViewModel: createPreviewViewModel(selectedGym: false),
        isPrimary: .constant(false),
        isPresented: .constant(true)
    )
}

#Preview("Loading State") {
    GymSelectionView(
        passViewModel: createPreviewViewModel(isLoading: true),
        isPrimary: .constant(true),
        isPresented: .constant(true)
    )
}

// Helper function to create a view model for previews
private func createPreviewViewModel(isLoading: Bool = false, selectedGym: Bool = true) -> PassViewModel {
    let viewModel = PassViewModel()
    
    // For the pass view, we might be using a simplified Gym model
    // If PassViewModel uses the full Gym model:
    viewModel.gyms = SampleData.gyms
    
    viewModel.isLoading = isLoading
    
    if !isLoading && !SampleData.gyms.isEmpty && selectedGym {
        viewModel.selectedGym = SampleData.gyms.first
    }
    
    return viewModel
}
