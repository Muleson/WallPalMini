//
//  UpcomingEventsView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/08/2025.
//

import SwiftUI

struct UpcomingEventsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = UpcomingViewModel()
    @State private var showingFilters = false
    @State private var selectedEvent: EventItem?
    @State private var selectedGym: Gym?
    @State private var currentCarouselIndex = 0
    @State private var showingSearchBar = false
    @FocusState private var searchFieldFocused: Bool
    
    // Featured events for carousel (first 3 events)
    private var featuredEvents: [EventItem] {
        Array(viewModel.filteredEvents.prefix(3))
    }
    
    // Gym class events for horizontal scroll
    private var gymClassEvents: [EventItem] {
        viewModel.filteredEvents.filter { $0.eventType == .gymClass }
    }
    
    // Social events for horizontal scroll
    private var socialEvents: [EventItem] {
        viewModel.filteredEvents.filter { $0.eventType == .social }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Inline search bar shown when toolbar search is activated
                    if showingSearchBar {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.appPrimary)

                            TextField("Search events, hosts or gyms", text: $viewModel.searchText)
                                .focused($searchFieldFocused)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: {
                                // Close search
                                showingSearchBar = false
                                viewModel.searchText = ""
                                searchFieldFocused = false
                            }) {
                                Text("Cancel")
                                    .foregroundColor(AppTheme.appPrimary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    // Gym Classes Horizontal Scroll
                    if !gymClassEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upgrade your beta")
                                .font(.appHeadline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(gymClassEvents) { event in
                                        CompactEventCard(event: event) {
                                            selectedEvent = event
                                        } onGymTap: { gym in
                                            selectedGym = gym
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 200)
                        }
                    }
                    
                    // Featured Events Carousel
                    if !featuredEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next big sends")
                                .font(.appHeadline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 4) {
                                TabView(selection: $currentCarouselIndex) {
                                    ForEach(featuredEvents.indices, id: \.self) { index in
                                        FeaturedEventCard(
                                            event: featuredEvents[index],
                                            onView: {
                                                selectedEvent = featuredEvents[index]
                                            },
                                            onRegister: {
                                                // Handle registration
                                                selectedEvent = featuredEvents[index]
                                            },
                                            onAddToCalendar: {
                                                // Handle add to calendar
                                                print("Add to calendar: \(featuredEvents[index].name)")
                                            },
                                            onGymTap: { gym in
                                                selectedGym = gym
                                            }
                                        )
                                        .padding(.horizontal)
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: 260)
                                
                                // Custom page indicator dots
                                HStack(spacing: 12) {
                                    ForEach(featuredEvents.indices, id: \.self) { index in
                                        Circle()
                                            .fill(currentCarouselIndex == index ? AppTheme.appPrimary : AppTheme.appPrimary.opacity(0.3))
                                            .frame(width: 4, height: 4)
                                            .animation(.easeInOut(duration: 0.3), value: currentCarouselIndex)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Social Events Horizontal Scroll
                    if !socialEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Social Sessions")
                                .font(.appHeadline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(socialEvents) { event in
                                        SocialEventCard(
                                            event: event,
                                            onTap: {
                                                selectedEvent = event
                                            },
                                            onGymTap: { gym in
                                                selectedGym = gym
                                            },
                                            onEventTap: { event in
                                                selectedEvent = event
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 170)
                        }
                    }
                    
                    // Filters section placeholder
                    HStack(spacing: 12) {
                        // Add filter buttons here later
                    }
                    .padding(.horizontal)

                    // Search results (show when user has typed something)
                    if !viewModel.searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search Results")
                                .font(.appHeadline)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(viewModel.filteredEvents) { event in
                                    StandardEventCard(event: event, onTap: {
                                        selectedEvent = event
                                    }, onGymTap: { gym in
                                        selectedGym = gym
                                    })
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("What's On")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSearchBar.toggle()
                        if showingSearchBar {
                            // focus the textfield on next runloop
                            DispatchQueue.main.async {
                                searchFieldFocused = true
                            }
                        } else {
                            viewModel.searchText = ""
                            searchFieldFocused = false
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventPageView(event: event)
            }
            .navigationDestination(item: $selectedGym) { gym in
                GymProfileView(gym: gym)
            }
            .refreshable {
                viewModel.fetchEvents()
            }
        }
    }
}
    
#Preview {
    UpcomingEventsView(appState: AppState())
}
