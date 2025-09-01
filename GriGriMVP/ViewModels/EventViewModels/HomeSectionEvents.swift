//
//  HomeSectionEvents.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation
import CoreLocation

/// Data structure for efficiently loading home section events
struct HomeSectionEvents {
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

/// Batch loading state for home sections
@MainActor
class HomeSectionLoader: ObservableObject {
    @Published private(set) var sectionEvents = HomeSectionEvents()
    @Published private(set) var error: Error?
    
    private let eventRepository: EventRepositoryProtocol
    private var loadingTask: Task<Void, Never>?
    
    init(eventRepository: EventRepositoryProtocol) {
        self.eventRepository = eventRepository
    }
    
    /// Load all home section events in parallel
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
                self.sectionEvents = HomeSectionEvents(isLoading: true)
                self.error = nil
            }
            
            do {
                // Load all sections in parallel for maximum efficiency
                async let classesTask = eventRepository.fetchClassesForHomeSection()
                async let featuredTask = eventRepository.fetchFeaturedEventsForCarousel()
                async let socialTask = eventRepository.fetchSocialEventsForHomeSection(userLocation: userLocation)
                
                let (classes, featured, social) = try await (classesTask, featuredTask, socialTask)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.sectionEvents = HomeSectionEvents(
                        classes: classes,
                        featuredCarousel: featured,
                        socialEvents: social,
                        isLoading: false,
                        lastUpdated: Date()
                    )
                }
                
                print("🏠 Loaded home sections: \(classes.count) classes, \(featured.count) featured, \(social.count) social")
                
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.error = error
                    self.sectionEvents = HomeSectionEvents(isLoading: false)
                }
                
                print("❌ Failed to load home sections: \(error)")
            }
        }
    }
    
    /// Refresh specific section
    func refreshSection(_ section: HomeSection, userLocation: CLLocation? = nil) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let currentSections = sectionEvents
                
                switch section {
                case .classes:
                    let classes = try await eventRepository.fetchClassesForHomeSection()
                    await MainActor.run {
                        self.sectionEvents = HomeSectionEvents(
                            classes: classes,
                            featuredCarousel: currentSections.featuredCarousel,
                            socialEvents: currentSections.socialEvents,
                            lastUpdated: Date()
                        )
                    }
                    
                case .featured:
                    let featured = try await eventRepository.fetchFeaturedEventsForCarousel()
                    await MainActor.run {
                        self.sectionEvents = HomeSectionEvents(
                            classes: currentSections.classes,
                            featuredCarousel: featured,
                            socialEvents: currentSections.socialEvents,
                            lastUpdated: Date()
                        )
                    }
                    
                case .social:
                    let social = try await eventRepository.fetchSocialEventsForHomeSection(userLocation: userLocation)
                    await MainActor.run {
                        self.sectionEvents = HomeSectionEvents(
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

enum HomeSection {
    case classes
    case featured
    case social
}
