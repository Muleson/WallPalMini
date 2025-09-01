//
//  SocialEventCardSkeleton.swift
//  GriGriMVP
//
//  Created to match SocialEventCard layout for loading state
//

import SwiftUI

struct SocialEventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 14)

                Spacer()
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 36)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 12)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 12)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 36)

        }
        .padding(.init(top: 14, leading: 10, bottom: 10, trailing: 10))
        .frame(width: 280, height: 150)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack(spacing: 12) {
        SocialEventCardSkeleton()
        SocialEventCardSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
