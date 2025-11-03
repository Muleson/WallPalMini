//
//  CompactEventCardSkeleton.swift
//  GriGriMVP
//
//  Created to match CompactEventCard layout for loading state
//

import SwiftUI

struct CompactEventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 90, height: 14)

                Spacer()
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 12)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 12)

            Spacer()

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(AppTheme.Spacing.cardPadding)
        .frame(width: 180)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
        .shimmer()
    }
}

#Preview {
    HStack(spacing: 12) {
        CompactEventCardSkeleton()
        CompactEventCardSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
