//
//  FavouriteGymsEvents.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import SwiftUI

struct FavoriteGymsEventsSection: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events at Your Favorite Gyms")
                .font(.appHeadline)
                .foregroundColor(AppTheme.appTextPrimary)
                .padding(.leading, 16)
            
            if viewModel.isLoadingEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.favoriteGymEvents.isEmpty {
                Text("No events from your favorite gyms")
                    .font(.appBody)
                    .foregroundColor(AppTheme.appTextLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.favoriteGymEvents) { event in
                            EventCardView(
                                event: event,
                                onFavorite: { viewModel.toggleFavorite(for: event) },
                                isFavorite: viewModel.isEventFavorited(event)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 24)
    }
}
