//
//  EventPageView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 06/06/2025.
//

import SwiftUI

struct EventPageView: View {
    let event: EventItem
    @StateObject private var viewModel: EventPageViewModel
    @StateObject private var colorService = MediaColorService.shared
    @State private var showShareSheet = false

    init(event: EventItem) {
        self.event = event
        self._viewModel = StateObject(wrappedValue: EventPageViewModel(event: event))
    }

    private func prominentColor(for mediaItem: MediaItem?) -> Color {
        // Use extracted color from media with neutral fallback
        colorService.getColor(for: mediaItem, fallback: AppTheme.appPrimary)
    }

    var body: some View {
        ZStack {
            // Background gradient from prominent color to white
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: prominentColor(for: event.mediaItems?.first).opacity(0.45), location: 0.15),
                    .init(color: .white, location: 0.75)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Event Media - centered, 2:3 aspect ratio (matching FeaturedEventCard)
                    Group {
                        if let firstMediaItem = event.mediaItems?.first {
                            AsyncImage(url: firstMediaItem.url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 320, height: 400)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } placeholder: {
                                eventMediaPlaceholder
                            }
                        } else {
                            eventMediaPlaceholder
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, -8)
                    .padding(.bottom, 24)

                    // Event Title
                    Text(event.name)
                        .font(.appHeadline)
                        .foregroundStyle(AppTheme.appTextPrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 16)

                    // Divider
                    Rectangle()
                        .fill(AppTheme.appSecondary)
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // Host and Date/Time section
                    HStack(spacing: 12) {
                        // Host profile image and name - tappable
                        Button(action: {
                            viewModel.navigateToGym()
                        }) {
                            HStack(spacing: 12) {
                                // Host profile image
                                CachedGymImageView(gym: event.host, size: 48)

                                // Host name
                                Text(event.host.name)
                                    .font(.appEventHost)
                                    .foregroundStyle(AppTheme.appPrimary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // Date and Time
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(viewModel.formattedEventDate)
                                .font(.system(size: 16, weight: .light, design: .rounded))
                                .foregroundStyle(AppTheme.appTextPrimary)

                            Text(viewModel.formattedTimeAndDuration)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(AppTheme.appTextLight)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    // Divider
                    Rectangle()
                        .fill(AppTheme.appSecondary)
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // Action buttons
                    HStack(spacing: 0) {
                        actionButton(
                            icon: viewModel.isSaved ? "bookmark.fill" : "bookmark",
                            label: viewModel.isSaved ? "Saved" : "Save",
                            isActive: viewModel.isSaved
                        ) {
                            viewModel.toggleSave()
                        }

                        actionButton(icon: "square.and.arrow.up", label: "Share", isActive: false) {
                            showShareSheet = true
                        }

                        actionButton(icon: "location.magnifyingglass", label: "Find", isActive: false) {
                            viewModel.openMaps()
                        }

                        actionButton(
                            icon: viewModel.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                            label: "Like",
                            isActive: viewModel.isLiked
                        ) {
                            viewModel.handleLike()
                        }

                        actionButton(
                            icon: viewModel.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                            label: "Dislike",
                            isActive: viewModel.isDisliked
                        ) {
                            viewModel.handleDislike()
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)

                    // Divider
                    Rectangle()
                        .fill(AppTheme.appSecondary)
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // Description section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Info")
                            .font(.appSubheadline)
                            .foregroundStyle(AppTheme.appPrimary)

                        HStack(spacing: 8) {
                            EventTypePill(eventType: event.eventType, size: .small)
                            
                            if let climbingTypes = event.climbingType {
                                ForEach(climbingTypes, id: \.self) { climbingType in
                                    ClimbingTypePill(climbingType: climbingType, size: .small)
                                }
                            }
                            
                            Spacer()
                        }

                        Text(event.description)
                            .font(.appBody)
                            .foregroundStyle(AppTheme.appTextPrimary)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)

                    Spacer(minLength: 20)
                }
            }
        }
        .shareSheet(isPresented: $showShareSheet, activityItems: ShareLinkHelper.eventShareItems(event: event))
        .background(
            NavigationLink(
                destination: GymProfileView(gym: viewModel.gym),
                isActive: $viewModel.shouldNavigateToGym
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    // MARK: - Event Media Placeholder

    private var eventMediaPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(prominentColor(for: event.mediaItems?.first).opacity(0.6))
                .frame(width: 320, height: 400)

            NegativeEventTypeIcons.icon(for: event.eventType)
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
        }
    }

    // MARK: - Action Button Helper

    @ViewBuilder
    private func actionButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? AppTheme.appPrimary : AppTheme.appTextLight)

                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isActive ? AppTheme.appPrimary : AppTheme.appTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        EventPageView(event: SampleData.events[3])
    }
}
