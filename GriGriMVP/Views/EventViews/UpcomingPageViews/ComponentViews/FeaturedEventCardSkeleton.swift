//
//  FeaturedEventCardSkeleton.swift
//  GriGriMVP
//
//  Created to match FeaturedEventCard layout for loading state
//

import SwiftUI

struct FeaturedEventCardSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 240)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 16)

                    Spacer()
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 14)

                Spacer()

                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 36)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 36)
                }
            }
            .padding(12)
            .frame(height: 240)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .appCardShadow()
        .shimmer()
    }
}

#Preview {
    FeaturedEventCardSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}
