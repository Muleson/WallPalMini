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
    @State private var localSearchText = ""
    @State private var showingFilters = false
    @State private var selectedEvent: EventItem?
    @State private var selectedGym: Gym?
    @State private var currentCarouselIndex = 0
    @State private var showingAllEvents = false
    @State private var showingFilterSheet = false
    
    // Featured events for carousel (optimized section loading)
    private var featuredEvents: [EventItem] {
        viewModel.featuredCarouselEvents
    }
    
    // Gym class events for horizontal scroll (optimized section loading)
    private var gymClassEvents: [EventItem] {
        viewModel.classEvents
    }
    
    // Social events for horizontal scroll (optimized section loading)
    private var socialEvents: [EventItem] {
        viewModel.socialEvents
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
                    
                    // Search results section (show when user has typed something)
                    if !localSearchText.isEmpty {
                        if viewModel.isLoadingEvents {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                                Text("Search Results")
                                    .font(.appHeadline)
                                    .padding(.horizontal, AppTheme.Spacing.screenPadding)

                                VStack(spacing: AppTheme.Spacing.sectionContentSpacing) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        StandardEventCardSkeleton()
                                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                                Text("Search Results")
                                    .font(.appHeadline)
                                    .padding(.horizontal, AppTheme.Spacing.screenPadding)

                                if viewModel.filteredEvents.isEmpty {
                                    Text("No events found")
                                        .font(.appBody)
                                        .foregroundColor(AppTheme.appTextLight)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                } else {
                                    VStack(spacing: AppTheme.Spacing.sectionContentSpacing) {
                                        ForEach(viewModel.filteredEvents) { event in
                                            StandardEventCard(event: event, onTap: {
                                                selectedEvent = event
                                            }, onGymTap: { gym in
                                                selectedGym = gym
                                            })
                                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Normal content sections when not searching
                        
                        // Gym Classes Horizontal Scroll
                        if viewModel.isSectionLoading {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                            Text("Classes")
                                .font(.appHeadline)
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.cardSpacing) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        CompactEventCardSkeleton()
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                .padding(.vertical, 4) // Add vertical padding to prevent shadow clipping
                            }
                        }
                    } else if !gymClassEvents.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                            Text("Classes")
                                .font(.appHeadline)
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: AppTheme.Spacing.cardSpacing) {
                                    ForEach(gymClassEvents) { event in
                                        CompactEventCard(event: event) {
                                            selectedEvent = event
                                        } onGymTap: { gym in
                                            selectedGym = gym
                                        }
                                    }
                                    
                                    // View More button for Classes
                                    ViewMoreButton(width: 180, title: "All Classes") {
                                        // Clear existing filters and set to gym classes only
                                        viewModel.clearAllFilters()
                                        viewModel.selectedEventTypes.insert(.gymClass)
                                        showingAllEvents = true
                                    }
                                    .padding(.leading, AppTheme.Spacing.xs)
                                }
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                .padding(.vertical, 4) // Add vertical padding to prevent shadow clipping
                            }
                        }
                    }
                    
                    // Featured Events Carousel
                    if viewModel.isSectionLoading {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                            Text("Next big sends")
                                .font(.appHeadline)
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)

                            VStack(spacing: AppTheme.Spacing.xs) {
                                TabView {
                                    ForEach(0..<3, id: \.self) { _ in
                                        FeaturedEventCardSkeleton()
                                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: 260)
                            }
                        }
                    } else if !featuredEvents.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                            Text("Next big sends")
                                .font(.appHeadline)
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                            
                            VStack(spacing: AppTheme.Spacing.xs) {
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
                                            onSave: {
                                                viewModel.toggleFavorite(for: featuredEvents[index])
                                            },
                                            isSaved: viewModel.isEventFavorited(featuredEvents[index]),
                                            onGymTap: { gym in
                                                selectedGym = gym
                                            }
                                        )
                                        .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: 260)
                                
                                // Custom page indicator dots
                                HStack(spacing: AppTheme.Spacing.cardSpacing) {
                                    ForEach(featuredEvents.indices, id: \.self) { index in
                                        Circle()
                                            .fill(currentCarouselIndex == index ? AppTheme.appPrimary : AppTheme.appPrimary.opacity(0.3))
                                            .frame(width: 4, height: 4)
                                            .animation(.easeInOut(duration: 0.3), value: currentCarouselIndex)
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                            }
                        }
                    }
                    
                    // Social Events Horizontal Scroll
                    if viewModel.isSectionLoading {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                            Text("Social Sessions")
                                .font(.appHeadline)
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.cardSpacing) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        SocialEventCardSkeleton()
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                .padding(.vertical, 4) // Add vertical padding to prevent shadow clipping
                            }
                        }
                    } else if !socialEvents.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionContentSpacing) {
                            Text("Social Sessions")
                                .font(.appHeadline)
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: AppTheme.Spacing.cardSpacing) {
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
                    
                                    // View More button for Social Sessions
                                    ViewMoreButton(width: 280, title: "All Social Sessions") {
                                        // Clear existing filters and set to social events only
                                        viewModel.clearAllFilters()
                                        viewModel.selectedEventTypes.insert(.social)
                                        showingAllEvents = true
                                    }
                                    .padding(.leading, AppTheme.Spacing.xs)
                                }
                                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                                .padding(.vertical, 4) // Add vertical padding to prevent shadow clipping
                            }
                        }
                    }
                    
                    // Filters section placeholder
                    HStack(spacing: AppTheme.Spacing.cardSpacing) {
                        // Add filter buttons here later
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    } // End of else block for normal content
                }
                .padding(.bottom, AppTheme.Spacing.screenPadding) // Add consistent bottom padding instead of Spacer
            }
            .navigationTitle("What's On")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(AppTheme.appPrimary)
                    }
                }
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventPageView(event: event)
            }
            .navigationDestination(item: $selectedGym) { gym in
                GymProfileView(gym: gym, appState: appState)
            }
            .navigationDestination(isPresented: $showingAllEvents) {
                FilteredEventsView(
                    appState: appState,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterBottomSheetView(
                    selectedEventTypes: $viewModel.selectedEventTypes,
                    selectedClimbingTypes: $viewModel.selectedClimbingTypes,
                    proximityFilter: $viewModel.proximityFilter,
                    onApplyFilters: {
                        showingAllEvents = true
                    }
                )
            }
            .refreshable {
                viewModel.loadUpcomingSections(forceRefresh: true)
            }
            .searchable(
                text: $localSearchText,
                placement: .automatic,
                prompt: "Search events, hosts or gyms"
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .onChange(of: localSearchText) { newValue in
                viewModel.searchText = newValue
            }
            .onAppear {
                viewModel.loadUpcomingSections()
                viewModel.searchText = localSearchText
            }
        }
    }
}
    
#Preview {
    UpcomingEventsView(appState: AppState())
}
