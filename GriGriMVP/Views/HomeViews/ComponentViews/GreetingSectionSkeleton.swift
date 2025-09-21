//
//  GreetingSectionSkeleton.swift
//  GriGriMVP
//
//  Created to match GreetingSection layout for loading state
//

import SwiftUI

struct GreetingSectionSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 32)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 32)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 220, height: 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    GreetingSectionSkeleton()
        .background(Color(AppTheme.appBackgroundBG))
}
