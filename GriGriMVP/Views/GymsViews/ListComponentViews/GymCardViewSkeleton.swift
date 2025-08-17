//
//  GymCardViewSkeleton.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/06/2025.
//

import SwiftUI

struct GymCardViewSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header with gym info and visit button skeleton
            HStack(spacing: 12) {
                // Gym profile image placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                // Gym name placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                // Visit button placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Horizontal view of events skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            // Event image placeholder
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 130, height: 160)
                                .clipped()
                            
                            // Event date placeholder
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(.bottom, 8)
                                .padding(.horizontal, 8)
                        }
                        .frame(width: 130)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 2, y: 2)
                        .padding(.bottom, 4) // Add padding to prevent shadow clipping
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack(spacing: 16) {
        GymCardViewSkeleton()
            .padding(.horizontal, 16)
        GymCardViewSkeleton()
            .padding(.horizontal, 16)
        GymCardViewSkeleton()
            .padding(.horizontal, 16)
    }
    .padding(.vertical, 16)
    .background(Color(.systemGroupedBackground))
}
