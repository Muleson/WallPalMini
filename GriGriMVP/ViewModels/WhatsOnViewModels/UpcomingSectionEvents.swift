//
//  UpcomingSectionEvents.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation
import CoreLocation

/// Data structure for efficiently loading upcoming section events
struct UpcomingSectionEvents {
    let classes: [EventItem]
    let featuredCarousel: [EventItem]  
    let socialEvents: [EventItem]
    let isLoading: Bool
    let lastUpdated: Date
    
    init(
        classes: [EventItem] = [],
        featuredCarousel: [EventItem] = [],
        socialEvents: [EventItem] = [],
        isLoading: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.classes = classes
        self.featuredCarousel = featuredCarousel
        self.socialEvents = socialEvents
        self.isLoading = isLoading
        self.lastUpdated = lastUpdated
    }
    
    /// Check if the data is stale (older than 15 minutes)
    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 15 * 60
    }
    
    /// Check if any section is empty
    var hasData: Bool {
        !classes.isEmpty || !featuredCarousel.isEmpty || !socialEvents.isEmpty
    }
}

/// Batch loading state for upcoming sections
@MainActor
class UpcomingSectionLoader: ObservableObject {
    @Published private(set) var sectionEvents = UpcomingSectionEvents()
    @Published private(set) var error: Error?
    
    private let eventRepository: EventRepositoryProtocol
    private var loadingTask: Task<Void, Never>?
    
    init(eventRepository: EventRepositoryProtocol) {
        self.eventRepository = eventRepository
    }
    
    /// Load all upcoming section events in parallel
    func loadAllSections(userLocation: CLLocation? = nil, forceRefresh: Bool = false) {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        // Skip loading if data is fresh and not forcing refresh
        if !forceRefresh && sectionEvents.hasData && !sectionEvents.isStale {
            return
        }
        
        loadingTask = Task { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.sectionEvents = UpcomingSectionEvents(isLoading: true)
                self.error = nil
            }
            
            do {
                // Load all sections in parallel for maximum efficiency
                async let classesTask = eventRepository.fetchClassesForUpcomingView()
                async let featuredTask = eventRepository.fetchFeaturedEventsForCarousel()
                async let socialTask = eventRepository.fetchSocialEventsForUpcomingView(userLocation: userLocation)
                
                let (classes, featured, social) = try await (classesTask, featuredTask, socialTask)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.sectionEvents = UpcomingSectionEvents(
                        classes: classes,
                        featuredCarousel: featured,
                        socialEvents: social,
                        isLoading: false,
                        lastUpdated: Date()
                    )
                }
                
                print("📅 Loaded upcoming sections: \(classes.count) classes, \(featured.count) featured, \(social.count) social")
                
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.error = error
                    self.sectionEvents = UpcomingSectionEvents(isLoading: false)
                }
                
                print("❌ Failed to load upcoming sections: \(error)")
            }
        }
    }
    
    /// Refresh specific section
    func refreshSection(_ section: UpcomingSection, userLocation: CLLocation? = nil) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let currentSections = sectionEvents
                
                switch section {
                case .classes:
                    let classes = try await eventRepository.fetchClassesForUpcomingView()
                    await MainActor.run {
                        self.sectionEvents = UpcomingSectionEvents(
                            classes: classes,
                            featuredCarousel: currentSections.featuredCarousel,
                            socialEvents: currentSections.socialEvents,
                            lastUpdated: Date()
                        )
                    }
                    
                case .featured:
                    let featured = try await eventRepository.fetchFeaturedEventsForCarousel()
                    await MainActor.run {
                        self.sectionEvents = UpcomingSectionEvents(
                            classes: currentSections.classes,
                            featuredCarousel: featured,
                            socialEvents: currentSections.socialEvents,
                            lastUpdated: Date()
                        )
                    }
                    
                case .social:
                    let social = try await eventRepository.fetchSocialEventsForUpcomingView(userLocation: userLocation)
                    await MainActor.run {
                        self.sectionEvents = UpcomingSectionEvents(
                            classes: currentSections.classes,
                            featuredCarousel: currentSections.featuredCarousel,
                            socialEvents: social,
                            lastUpdated: Date()
                        )
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    deinit {
        loadingTask?.cancel()
    }
}

enum UpcomingSection {
    case classes
    case featured
    case social
}
