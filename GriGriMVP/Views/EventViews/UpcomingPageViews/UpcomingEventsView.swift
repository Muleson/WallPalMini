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
    @State private var currentCarouselIndex = 0
    
    // Featured events for carousel (first 3 events)
    private var featuredEvents: [EventItem] {
        Array(viewModel.filteredEvents.prefix(3))
    }
    
    // Gym class events for horizontal scroll
    private var gymClassEvents: [EventItem] {
        viewModel.filteredEvents.filter { $0.eventType == .gymClass }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                    
                    // Filters section placeholder
                    HStack(spacing: 12) {
                        // Add filter buttons here later
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("What's On")
            .navigationDestination(item: $selectedEvent) { event in
                EventPageView(event: event)
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
