//
//  SavedEventsViewModel.swift
//  GriGriMVP
//
//  Created by Claude Code on 14/10/2025.
//

import Foundation
import Combine

@MainActor
class SavedEventsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var savedEvents: [EventItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false

    // MARK: - Private Properties
    private let userRepository: UserRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentUser: User?

    // MARK: - Computed Properties

    /// Returns only events of type .gymClass
    var savedClasses: [EventItem] {
        savedEvents.filter { $0.eventType == .gymClass }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Returns all non-class events
    var savedNonClassEvents: [EventItem] {
        savedEvents.filter { $0.eventType != .gymClass }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Initialization

    init(userRepository: UserRepositoryProtocol = RepositoryFactory.createUserRepository(),
         eventRepository: EventRepositoryProtocol? = nil) {
        self.userRepository = userRepository
        self.eventRepository = eventRepository ?? RepositoryFactory.createEventRepository()

        fetchSavedEvents()
    }

    // MARK: - Data Fetching

    func fetchSavedEvents() {
        isLoading = true

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Get current user
                guard let user = try await userRepository.getCurrentUser() else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "User not found"
                        self.hasError = true
                    }
                    return
                }

                await MainActor.run {
                    self.currentUser = user
                }

                // Check if user has any favorite events
                guard user.favoriteEvents?.isEmpty == false else {
                    await MainActor.run {
                        self.savedEvents = []
                        self.isLoading = false
                    }
                    return
                }

                // Fetch all favorite events using the repository method
                let events = try await eventRepository.fetchFavoriteEvents(userId: user.id)

                // Filter out past one-time events, but keep recurring events
                let currentDate = Date()
                let filteredEvents = events.filter { event in
                    // Include if it's a future event
                    if event.startDate > currentDate {
                        return true
                    }

                    // Include if it's a recurring event (even if original start date is past)
                    if event.frequency != nil {
                        return true
                    }

                    // Exclude past one-time events
                    return false
                }

                await MainActor.run {
                    self.savedEvents = filteredEvents.sorted { $0.startDate < $1.startDate }
                    self.isLoading = false
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load saved events: \(error.localizedDescription)"
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Favorite Management

    func removeFromFavorites(_ event: EventItem) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                if let userId = userRepository.getCurrentAuthUser() {
                    // Update in repository
                    _ = try await userRepository.updateUserFavoriteEvents(
                        userId: userId,
                        eventId: event.id,
                        isFavorite: false
                    )

                    await MainActor.run {
                        // Remove from local array
                        self.savedEvents.removeAll { $0.id == event.id }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                    self.hasError = true
                }
            }
        }
    }

    // MARK: - Refresh

    func refresh() {
        fetchSavedEvents()
    }
}
