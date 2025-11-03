//
//  FilteredEventsView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 02/09/2025.
//

import SwiftUI

struct FilteredEventsView: View {
    let appState: AppState
    @ObservedObject var viewModel: UpcomingViewModel
    
    @State private var selectedEvent: EventItem?
    @State private var selectedGym: Gym?
    @State private var showingFilterSheet = false
    
    init(appState: AppState, viewModel: UpcomingViewModel) {
        self.appState = appState
        self.viewModel = viewModel
    }
    
    // Computed property for dynamic navigation title
    private var navigationTitle: String {
        if viewModel.selectedEventTypes.count == 1 {
            let eventType = viewModel.selectedEventTypes.first!
            switch eventType {
            case .gymClass:
                return "Classes"
            case .social:
                return "Social Events"
            default:
                return eventType.displayName
            }
        } else if viewModel.hasActiveFilters {
            return "Filtered Events"
        } else {
            return "All Events"
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Show active filter summary if filters are applied
                // Temporarily commented out event type pills
                /*
                if viewModel.hasActiveFilters {
                    HStack {
                        if viewModel.selectedEventTypes.count == 1 {
                            let eventType = viewModel.selectedEventTypes.first!
                            Text(eventType.displayName)
                                .font(.appCaption)
                                .foregroundColor(AppTheme.appPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.appPrimary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                */
                
                if viewModel.filteredEvents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.appTextLight)
                        
                        Text("No events match your filters")
                            .font(.appSubheadline)
                            .foregroundColor(AppTheme.appTextLight)
                            .multilineTextAlignment(.center)
                        
                        Text("Try adjusting your filter criteria")
                            .font(.appCaption)
                            .foregroundColor(AppTheme.appTextLight)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(viewModel.filteredEvents) { event in
                        StandardEventCard(
                            event: event,
                            onTap: {
                                selectedEvent = event
                            },
                            onGymTap: { gym in
                                selectedGym = gym
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Fetch events using optimized server-side filtered query
            // Only loads events matching current filter criteria to minimize database reads
            viewModel.fetchFilteredEvents()
        }
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
        .sheet(isPresented: $showingFilterSheet) {
            FilterBottomSheetView(
                selectedEventTypes: $viewModel.selectedEventTypes,
                selectedClimbingTypes: $viewModel.selectedClimbingTypes,
                proximityFilter: $viewModel.proximityFilter,
                onApplyFilters: {
                    // Filters are already applied through bindings, just dismiss
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        FilteredEventsView(
            appState: AppState(),
            viewModel: UpcomingViewModel()
        )
    }
}
