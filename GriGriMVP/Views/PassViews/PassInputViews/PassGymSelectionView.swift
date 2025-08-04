//
//  TitleInputView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 29/03/2025.
//

import SwiftUI

struct GymSelectionView: View {
    @ObservedObject var viewModel: PassCreationViewModel
    @State private var searchText: String = ""
    @State private var showScanner: Bool = false // Keep this for navigation destination
    @State private var debounceTimer: Timer?
    
    let onPassAdded: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Search bar
            searchBarView
            
            Text("Select your gym")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Show loading state or error
            contentView
            
            // Action buttons
            actionButtonsView
        }
        .navigationTitle("Add New Pass")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadGyms()
        }
        .navigationDestination(isPresented: $showScanner) {
            PassScannerView(
                creationViewModel: viewModel,
                onPassAdded: onPassAdded
            )
        }
    }
    
    // MARK: - Subviews
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search gyms", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: searchText, perform: handleSearchTextChange)
            
            if !searchText.isEmpty {
                Button(action: clearSearch) {
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
    }
    
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading gyms...")
                Spacer()
            } else if let error = viewModel.searchError {
                Spacer()
                VStack(spacing: 16) {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        viewModel.loadGyms()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            } else if viewModel.gyms.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "building.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No gyms found")
                        .foregroundColor(.secondary)
                    if !searchText.isEmpty {
                        Text("Try adjusting your search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            } else {
                gymListView
            }
        }
    }
    
    private var gymListView: some View {
        List {
            ForEach(viewModel.gyms) { gym in
                GymRow(
                    gym: gym,
                    isSelected: gym.id == viewModel.selectedGym?.id,
                    distance: viewModel.gymDistances[gym.id]
                )
                .onTapGesture {
                    viewModel.selectedGym = gym
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            scanButton
            // Removed cancel button since navigation back button handles this
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var scanButton: some View {
        Button(action: handleScanButtonTap) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                Text("Scan Pass")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.selectedGym == nil ? Color.gray : AppTheme.appPrimary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(viewModel.selectedGym == nil ? 0.6 : 1.0)
        }
        .disabled(viewModel.selectedGym == nil)
    }
    
    // MARK: - Actions
    
    private func handleSearchTextChange(_ newValue: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            if newValue.isEmpty {
                viewModel.loadGyms()
            } else {
                viewModel.searchGyms(query: newValue)
            }
        }
    }
    
    private func clearSearch() {
        searchText = ""
        viewModel.loadGyms()
    }
    
    private func handleScanButtonTap() {
        guard let gym = viewModel.selectedGym else { return }
        
        viewModel.prepareForScan(with: gym)
        showScanner = true
    }
}

// GymRow helper view
struct GymRow: View {
    let gym: Gym
    let isSelected: Bool
    let distance: String? // Pass distance from ViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Gym logo with better error handling
            gymImageView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gym.name)
                    .font(.body)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? AppTheme.appPrimary : AppTheme.appTextPrimary)
                
                subtitleView
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.appPrimary)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
    
    private var gymImageView: some View {
        Group {
            if let profileImage = gym.profileImage {
                AsyncImage(url: profileImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderImage
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderImage
            }
        }
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: "building.2")
                    .foregroundColor(.secondary)
                    .font(.title2)
            )
    }
    
    private var subtitleView: some View {
        Group {
            if let distance = distance {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let address = gym.location.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("Location unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}
