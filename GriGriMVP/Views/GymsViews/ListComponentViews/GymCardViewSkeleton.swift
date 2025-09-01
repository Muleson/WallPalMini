//
//  GymCardViewSkeleton.swift
//  GriGriMVP
//
//  Updated to mirror LargeGymCardView layout (header + climbing type placeholders)
//

import SwiftUI

struct GymCardViewSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            // Top header: profile, name, distance, visit button
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 160, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 90, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 96, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Climbing type icons with labels
            HStack(spacing: 20) {
                Spacer()
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 10)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack(spacing: 16) {
        GymCardViewSkeleton()
            .padding(.horizontal, 16)
        GymCardViewSkeleton()
            .padding(.horizontal, 16)
    }
    .padding(.vertical, 16)
    .background(Color(.systemGroupedBackground))
}
