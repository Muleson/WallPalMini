//
//  NearbyGymRowSkeleton.swift
//  GriGriMVP
//
//  Created to match NearbyGymRow layout for loading state
//

import SwiftUI

struct NearbyGymRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // NearbyGymCard skeleton
            HStack(spacing: 12) {
                // Gym icon placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 20)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 14)
                }
                
                Spacer()
                
                // QR Code button placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .appCardShadow()
            
            // AddPassButton skeleton
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .appCardShadow()
        }
        .redacted(reason: .placeholder)
    }
}

#Preview {
    NearbyGymRowSkeleton()
        .padding(.horizontal, 12)
        .padding(.top, 24)
        .background(Color(.systemGroupedBackground))
}
