//
//  AddressInputView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 10/06/2025.
//

import SwiftUI

struct AddressInputView: View {
    @Binding var address: String
    let isLoading: Bool
    let locationPermissionGranted: Bool
    let onAddressChange: () -> Void
    let onLocationButtonTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Gym Address", text: $address)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .onChange(of: address) { _ in
                        onAddressChange()
                    }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                if locationPermissionGranted {
                    Button(action: onLocationButtonTapped) {
                        Image(systemName: "location")
                            .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.appContentBG)
            .cornerRadius(12)
        }
    }
}

#Preview {
    AddressInputView(
        address: .constant("123 Main Street"),
        isLoading: false,
        locationPermissionGranted: true,
        onAddressChange: {},
        onLocationButtonTapped: {}
    )
    .padding()
    .background(AppTheme.appBackgroundBG)
}
