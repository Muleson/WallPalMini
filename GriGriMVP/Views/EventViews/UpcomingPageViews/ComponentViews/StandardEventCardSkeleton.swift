//
//  StandardEventCardSkeleton.swift
//  GriGriMVP
//
//  Created to match StandardEventCard layout for loading state
//

import SwiftUI

struct StandardEventCardSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 94, height: 140)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 18, height: 18)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 14)

                    Spacer()

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 20)
                        .clipShape(Capsule())
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 36)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 90, height: 12)

                Spacer()

                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 64, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .frame(height: 140)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
        .shimmer()
    }
}

#Preview {
    VStack(spacing: 12) {
        StandardEventCardSkeleton()
        StandardEventCardSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
