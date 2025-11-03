//
//  CompactGymCardSkeleton.swift
//  GriGriMVP
//
//  Created to match CompactGymCard layout for loading state
//

import SwiftUI

struct CompactGymCardSkeleton: View {
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()
            }

            // Climbing type icons row
            HStack {
                Spacer()
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 8)
        }
        .frame(width: 200, height: 140)
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
        .shimmer()
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            CompactGymCardSkeleton()
            CompactGymCardSkeleton()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
