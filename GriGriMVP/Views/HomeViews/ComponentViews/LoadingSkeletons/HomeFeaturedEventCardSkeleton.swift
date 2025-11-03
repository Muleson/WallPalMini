//
//  HomeFeaturedEventCardSkeleton.swift
//  GriGriMVP
//
//  Created to match HomeFeaturedEventCard layout for loading state
//

import SwiftUI

struct HomeFeaturedEventCardSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            // Event media section placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 240)
            
            // Event details section placeholder
            VStack(alignment: .leading, spacing: 12) {
                // Host/venue info placeholder
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 14)
                    
                    Spacer()
                }
                
                // Date placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                
                // Time placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)
                
                // Event type tag placeholder
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 18)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                
                Spacer()
                
                // Action buttons placeholder
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .frame(height: 240)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .appCardShadow()
        .shimmer()
    }
}

#Preview {
    HomeFeaturedEventCardSkeleton()
        .padding(.horizontal, 12)
        .background(Color(.systemGroupedBackground))
}
