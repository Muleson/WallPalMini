//
//  WebsitePriceCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 08/10/2025.
//
import SwiftUI

struct WebsitePriceCard: View {
    let websiteURL: String?
    
    var body: some View {
        if let websiteURL = websiteURL, let url = URL(string: websiteURL) {
            Link(destination: url) {
                HStack {
                    Text("View Pricing & Memberships")
                        .font(.appBody)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .foregroundColor(AppTheme.appPrimary)
                .padding()
                .background(AppTheme.appContentBG.opacity(0.5))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
}
