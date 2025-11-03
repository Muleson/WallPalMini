//
//  SavedClassesView.swift
//  GriGriMVP
//
//  Created by Claude Code on 14/10/2025.
//

import SwiftUI

struct SavedClassesView: View {
    @StateObject private var viewModel = SavedEventsViewModel()
    @State private var selectedEvent: EventItem?
    @State private var selectedGym: Gym?
    @State private var eventToShare: EventItem?

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.top, 60)
            } else if viewModel.savedClasses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.appTextLight)

                    Text("No saved classes")
                        .font(.appSubheadline)
                        .foregroundColor(AppTheme.appTextLight)
                        .multilineTextAlignment(.center)

                    Text("Classes you save will appear here")
                        .font(.appCaption)
                        .foregroundColor(AppTheme.appTextLight)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.top, 60)
            } else {
                ForEach(viewModel.savedClasses) { event in
                    SavedEventCard(
                        event: event,
                        onTap: {
                            selectedEvent = event
                        },
                        onUnsave: {
                            viewModel.removeFromFavorites(event)
                        },
                        onShare: {
                            eventToShare = event
                        },
                        onGymTap: { gym in
                            selectedGym = gym
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .background(Color(AppTheme.appBackgroundBG))
        .navigationTitle("Your Classes")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            viewModel.refresh()
        }
        .navigationDestination(item: $selectedEvent) { event in
            EventPageView(event: event)
        }
        .navigationDestination(item: $selectedGym) { gym in
            GymProfileView(gym: gym, appState: AppState())
        }
        .sheet(item: $eventToShare) { event in
            ShareSheet(activityItems: [createShareMessage(for: event)])
        }
        .alert(isPresented: $viewModel.hasError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func createShareMessage(for event: EventItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return """
        Check out this class: \(event.name)

        📍 \(event.host.name)
        📅 \(formatter.string(from: event.startDate))

        \(event.description)
        """
    }
}

#Preview {
    NavigationStack {
        SavedClassesView()
    }
}
