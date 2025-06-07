//
//  QuickActionButtons.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct QuickActionButton: View {
    var body: some View {
        HStack(spacing: 8) {
            NavigationLink {
                HomeView(appState: AppState()) //To navigate to a gym search view
            } label: {
                VStack {
                    Text("Find Gyms")
                        .font(.appButtonPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .foregroundColor(.textButton)
                .background(AppTheme.appSecondary)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
            
            NavigationLink {
                PassesRootView()
            } label: {
                VStack {
                    Text("View Pass")
                        .font(.appButtonPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .foregroundColor(.textButton)
                .background(AppTheme.appPrimary)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    QuickActionButton()
}
