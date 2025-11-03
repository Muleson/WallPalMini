//
//  MainTabView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI
import VisionKit

struct MainTabView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab = 0 // Start with "Home" tab (0-indexed)

    // State to hold the event/gym to navigate to via deep links
    @State private var pendingEventNavigation: EventItem?
    @State private var pendingGymNavigation: Gym?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(appState: appState)
                    .navigationDestination(for: EventItem.self) { event in
                        EventPageView(event: event)
                    }
                    .navigationDestination(for: Gym.self) { gym in
                        GymProfileView(gym: gym)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)


            NavigationStack {
                PassesRootView(appState: appState)
            }
            .tabItem {
                Label("Passes", systemImage: "qrcode.viewfinder")
            }
            .tag(1)

            NavigationStack {
                UpcomingEventsView(appState: appState)
                    .navigationDestination(for: EventItem.self) { event in
                        EventPageView(event: event)
                    }
                    .navigationDestination(isPresented: Binding(
                        get: { pendingEventNavigation != nil },
                        set: { if !$0 { pendingEventNavigation = nil } }
                    )) {
                        if let event = pendingEventNavigation {
                            EventPageView(event: event)
                        }
                    }
            }
            .tabItem {
                Label("What's On", systemImage: "calendar.badge.clock")
            }
            .tag(2)

            NavigationStack {
                GymsListView(appState: appState)
                    .navigationDestination(for: Gym.self) { gym in
                        GymProfileView(gym: gym)
                    }
                    .navigationDestination(isPresented: Binding(
                        get: { pendingGymNavigation != nil },
                        set: { if !$0 { pendingGymNavigation = nil } }
                    )) {
                        if let gym = pendingGymNavigation {
                            GymProfileView(gym: gym)
                        }
                    }
            }
            .tabItem {
                Label("Gyms", systemImage: "building.2")
            }
            .tag(3)
        }
        .tint(AppTheme.appPrimary)
        .onAppear {
            // Check for pending deep links when view appears
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                handlePendingDeepLink()
            }
        }
        .onReceive(appState.deepLinkManager.$pendingDeepLink) { _ in
            // Handle deep links when they change
            handlePendingDeepLink()
        }
    }

    private func handlePendingDeepLink() {
        guard let destination = appState.deepLinkManager.pendingDeepLink else {
            return
        }

        switch destination {
        case .home:
            withAnimation {
                selectedTab = 0
            }

        case .passes:
            withAnimation {
                selectedTab = 1
            }

        case .whatsOn:
            withAnimation {
                selectedTab = 2
            }

        case .gyms:
            withAnimation {
                selectedTab = 3
            }

        case .event(let id):
            withAnimation {
                selectedTab = 2 // Switch to What's On tab
            }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // Allow tab switch to complete
                await navigateToEvent(id: id)
            }

        case .gym(let id):
            withAnimation {
                selectedTab = 3 // Switch to Gyms tab
            }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // Allow tab switch to complete
                await navigateToGym(id: id)
            }
        }

        appState.deepLinkManager.clearPendingDeepLink()
    }

    private func navigateToEvent(id: String) async {
        let eventRepository = RepositoryFactory.createEventRepository()
        do {
            if let event = try await eventRepository.getEvent(id: id) {
                await MainActor.run {
                    pendingEventNavigation = event
                }
            }
        } catch {
            print("Error fetching event for deep link: \(error)")
        }
    }

    private func navigateToGym(id: String) async {
        let gymRepository = RepositoryFactory.createGymRepository()
        do {
            if let gym = try await gymRepository.getGym(id: id) {
                await MainActor.run {
                    pendingGymNavigation = gym
                }
            }
        } catch {
            print("Error fetching gym for deep link: \(error)")
        }
    }
}


#Preview {
    MainTabView(appState: AppState())
}
