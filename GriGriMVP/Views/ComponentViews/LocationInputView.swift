//
//  LocationInputView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/08/2025.
//

import SwiftUI

struct LocationInputView: View {
    @Binding var address: String
    @Binding var isSearchingAddresses: Bool
    @Binding var showAddressSuggestions: Bool
    @Binding var addressSuggestions: [AddressSuggestion]
    @Binding var isLocationLoading: Bool
    @Binding var useCurrentLocation: Bool
    
    let shouldShowLocationButton: Bool
    let canUseCurrentLocation: Bool
    let locationStatusMessage: String
    let onAddressChange: () -> Void
    let onGetCurrentLocation: () -> Void
    let onSelectSuggestion: (AddressSuggestion) -> Void
    let onRequestLocationPermission: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main address input with location controls
            VStack(spacing: 0) {
                HStack {
                    TextField("Gym Address", text: $address)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.appTextPrimary)
                        .onChange(of: address) { _ in
                            onAddressChange()
                        }
                        .disabled(isLocationLoading)
                    
                    if isSearchingAddresses {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Spacer()
                    
                    locationControls
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.appContentBG)
                
                // Location status indicator
                if shouldShowLocationButton && !canUseCurrentLocation {
                    locationStatusBar
                }
            }
            .cornerRadius(12)
            
            // Current location indicator
            if useCurrentLocation && !address.isEmpty {
                currentLocationIndicator
            }
            
            // Address suggestions dropdown
            if showAddressSuggestions {
                addressSuggestionsDropdown
            }
        }
    }
    
    private var locationControls: some View {
        HStack(spacing: 8) {
            if isLocationLoading {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Getting location...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if canUseCurrentLocation {
                Button(action: onGetCurrentLocation) {
                    HStack(spacing: 4) {
                        Image(systemName: useCurrentLocation ? "location.fill" : "location")
                            .foregroundColor(useCurrentLocation ? AppTheme.appPrimary : .secondary)
                        Text("Use Current")
                            .font(.caption)
                            .foregroundColor(useCurrentLocation ? AppTheme.appPrimary : .secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else if shouldShowLocationButton {
                Button(action: onRequestLocationPermission) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.slash")
                            .foregroundColor(.orange)
                        Text("Enable")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var locationStatusBar: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text(locationStatusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Settings") {
                onRequestLocationPermission()
            }
            .font(.caption)
            .foregroundColor(AppTheme.appPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
    
    private var currentLocationIndicator: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(AppTheme.appPrimary)
                .font(.caption)
            
            Text("Using your current location")
                .font(.caption)
                .foregroundColor(AppTheme.appPrimary)
            
            Spacer()
            
            Button("Clear") {
                useCurrentLocation = false
                address = ""
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.appPrimary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var addressSuggestionsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(addressSuggestions) { suggestion in
                Button(action: {
                    onSelectSuggestion(suggestion)
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(suggestion.displayAddress)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.appTextPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                if suggestion.id != addressSuggestions.last?.id {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .background(AppTheme.appContentBG)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
struct LocationInputView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal state
            LocationInputView(
                address: .constant(""),
                isSearchingAddresses: .constant(false),
                showAddressSuggestions: .constant(false),
                addressSuggestions: .constant([]),
                isLocationLoading: .constant(false),
                useCurrentLocation: .constant(false),
                shouldShowLocationButton: true,
                canUseCurrentLocation: true,
                locationStatusMessage: "Location available",
                onAddressChange: {},
                onGetCurrentLocation: {},
                onSelectSuggestion: { _ in },
                onRequestLocationPermission: {}
            )
            
            // Permission denied state
            LocationInputView(
                address: .constant(""),
                isSearchingAddresses: .constant(false),
                showAddressSuggestions: .constant(false),
                addressSuggestions: .constant([]),
                isLocationLoading: .constant(false),
                useCurrentLocation: .constant(false),
                shouldShowLocationButton: true,
                canUseCurrentLocation: false,
                locationStatusMessage: "Location access denied. Tap to open Settings.",
                onAddressChange: {},
                onGetCurrentLocation: {},
                onSelectSuggestion: { _ in },
                onRequestLocationPermission: {}
            )
            
            // Using current location state
            LocationInputView(
                address: .constant("123 Main St, New York, NY"),
                isSearchingAddresses: .constant(false),
                showAddressSuggestions: .constant(false),
                addressSuggestions: .constant([]),
                isLocationLoading: .constant(false),
                useCurrentLocation: .constant(true),
                shouldShowLocationButton: true,
                canUseCurrentLocation: true,
                locationStatusMessage: "Location available",
                onAddressChange: {},
                onGetCurrentLocation: {},
                onSelectSuggestion: { _ in },
                onRequestLocationPermission: {}
            )
        }
        .padding()
        .background(AppTheme.appBackgroundBG)
    }
}
