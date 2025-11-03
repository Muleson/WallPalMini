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
    @State private var showShareSheet = false

    init(event: EventItem) {
        self.event = event
        self._viewModel = StateObject(wrappedValue: EventPageViewModel(event: event))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Event Name
                Text(event.name)
                    .font(.appHeadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                    .padding()
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Event date and time section
                HStack(spacing: 8) {
                    Text(viewModel.formattedEventDate)
                        .font(.appSubheadline)
                        .foregroundStyle(AppTheme.appTextPrimary)
                    
                    Text(viewModel.formattedTimeAndDuration)
                        .font(.appUnderline)
                        .foregroundColor(AppTheme.appTextLight)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Host and location section
                HStack {
                    // Profile image placeholder
                    if let profileImage = event.host.profileImage {
                        AsyncImage(url: profileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 48)
                        }
                    } else {
                        Image(systemName: "building.2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray)
                    }
                    Text(event.host.name)
                        .font(.appEventHost)
                        .foregroundStyle(AppTheme.appPrimary)
                    
                    Spacer()
                    
                    // Maps button
                    PrimaryActionButton.outlineCompact("View in Maps") {
                        viewModel.openMaps()
                    }
                    .frame(maxWidth: 128)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.appSecondary)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                
                // Event media section
                if viewModel.hasMediaItems {
                    GeometryReader { geometry in
                        TabView {
                            ForEach(viewModel.mediaItems, id: \.id) { mediaItem in
                                AsyncImage(url: mediaItem.url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: geometry.size.width - 16, height: (geometry.size.width - 16) * 3/2)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: viewModel.mediaItems.count > 1 ? .automatic : .never))
                        .frame(height: (geometry.size.width - 16) * 3/2)
                    }
                    .frame(height: UIScreen.main.bounds.width * 3/2 - 24)
                    .padding(.horizontal, 8)
                    .padding(.top, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(AppTheme.appSecondary)
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                }
                
                // Description section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.appSubheadline)
                        .foregroundStyle(AppTheme.appPrimary)
                    
                    Text(event.description)
                        .font(.appBody)
                        .lineLimit(nil)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                Spacer(minLength: 20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.appPrimary)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating register button
            if event.registrationRequired {
                PrimaryActionButton.primary("Register") {
                    viewModel.handleRegistration()
                }
                .frame(width: 120)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .shareSheet(isPresented: $showShareSheet, activityItems: ShareLinkHelper.eventShareItems(event: event))
    }
}

#Preview {
    NavigationView {
        EventPageView(event: SampleData.events[3])
    }
}
