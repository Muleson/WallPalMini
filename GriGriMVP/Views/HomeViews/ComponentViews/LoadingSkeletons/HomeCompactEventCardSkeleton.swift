//
//  HomeCompactEventCardSkeleton.swift
//  GriGriMVP
//
//  Created to match HomeCompactEventCard layout for loading state
//

import SwiftUI

struct HomeCompactEventCardSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 270)
                
                // Gradient overlay to match the real card
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.4),
                        .init(color: Color.gray.opacity(0.4), location: 0.8),
                        .init(color: Color.gray.opacity(0.6), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Overlay content placeholder
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Main title placeholder
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 100, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            // Subtitle placeholder
                            Rectangle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 80, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        // Gym logo placeholder - fixed position
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .frame(width: 180, height: 270)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .appCardShadow()
        .shimmer()
    }
}

#Preview {
    HStack(spacing: 12) {
        HomeCompactEventCardSkeleton()
        HomeCompactEventCardSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
