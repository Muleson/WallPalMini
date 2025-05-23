//
//  QuickActionButtons.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct QuickActionButton: View {
    var body: some View {
        NavigationLink {
            PassesRootView()
        } label: {
            VStack {
                Text("View Pass")
                    .font(.appHeadline)
            }
            .frame(maxWidth: 306)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(AppTheme.appAccent)
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
}

#Preview {
    QuickActionButton()
}
