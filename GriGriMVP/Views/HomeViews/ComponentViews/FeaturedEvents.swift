//
//  FeaturedEvents.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct FeaturedEventsSection: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Featured Events")
                .font(.appHeadline)
                .foregroundColor(AppTheme.appTextPrimary)
                .padding(.leading, 16)
            
            if viewModel.isLoadingEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.featuredEvents.isEmpty {
                Text("No featured events available")
                    .font(.appBody)
                    .foregroundColor(AppTheme.appTextLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.featuredEvents) { event in
                            EventCardView(
                                event: event,
                                onFavorite: { viewModel.toggleFavorite(for: event) },
                                isFavorite: viewModel.isEventFavorited(event)
                            )
                            .frame(width: 250)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
