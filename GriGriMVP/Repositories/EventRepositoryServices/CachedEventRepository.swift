//
//  CachedEventRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation
import CoreLocation

/// Cached decorator for EventRepositoryProtocol that adds memory caching
final class CachedEventRepository: EventRepositoryProtocol {
    
    // MARK: - Private Properties
    
    private let baseRepository: EventRepositoryProtocol
    private let eventCache: MemoryCache<EventItem>
    private let searchCache: MemoryCache<[String]>
    private let userCache: MemoryCache<User>
    private let gymCache: MemoryCache<Gym>
    
    // MARK: - Initialization
    
    init(baseRepository: EventRepositoryProtocol,
         eventCache: MemoryCache<EventItem>? = nil,
         searchCache: MemoryCache<[String]>? = nil,
         userCache: MemoryCache<User>? = nil,
         gymCache: MemoryCache<Gym>? = nil) {
        self.baseRepository = baseRepository
        self.eventCache = eventCache ?? CacheManager.shared.eventCache
        self.searchCache = searchCache ?? CacheManager.shared.searchCache
        self.userCache = userCache ?? CacheManager.shared.userCache
        self.gymCache = gymCache ?? CacheManager.shared.gymCache
    }
    
    // MARK: - EventRepositoryProtocol Implementation
    
    func fetchAllEvents() async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.allEvents()
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchAllEvents (\(cachedEvents.count) events)")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchAllEvents - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchAllEvents()
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) events with related entities")
        return events
    }
    
    func fetchEventsForGym(gymId: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.eventsForGym(gymId)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchEventsForGym(\(gymId)) - \(cachedEvents.count) events")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchEventsForGym(\(gymId)) - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchEventsForGym(gymId: gymId)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs for this gym
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) events for gym \(gymId)")
        return events
    }
    
    func fetchEventsCreatedByUser(userId: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.eventsForUser(userId)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchEventsCreatedByUser(\(userId)) - \(cachedEvents.count) events")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchEventsCreatedByUser(\(userId)) - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchEventsCreatedByUser(userId: userId)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs for this user
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) events created by user \(userId)")
        return events
    }
    
    func fetchFavoriteEvents(userId: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.favoriteEvents(userId)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchFavoriteEvents(\(userId)) - \(cachedEvents.count) events")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchFavoriteEvents(\(userId)) - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchFavoriteEvents(userId: userId)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of favorite event IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) favorite events for user \(userId)")
        return events
    }
    
    func searchEvents(query: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.eventSearch(query)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: searchEvents('\(query)') - \(cachedEvents.count) results")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: searchEvents('\(query)') - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.searchEvents(query: query)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the search result IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached search result for '\(query)': \(events.count) events")
        return events
    }
    
    func getEvent(id: String) async throws -> EventItem? {
        let cacheKey = CacheManager.CacheKeys.eventById(id)
        
        // Try cache first
        if let cachedEvent = eventCache.get(forKey: cacheKey) {
            print("🎯 Cache hit: getEvent(\(id))")
            return cachedEvent
        }
        
        print("🌐 Cache miss: getEvent(\(id)) - fetching from source")
        
        // Fetch from base repository
        let event = try await baseRepository.getEvent(id: id)
        
        // Cache the result if found
        if let event = event {
            await cacheEventsAndRelatedEntities([event])
            print("💾 Cached event: \(event.name)")
        }
        
        return event
    }
    
    func createEvent(_ event: EventItem) async throws -> String {
        // Create in base repository
        let eventId = try await baseRepository.createEvent(event)
        
        // Create a new event with the generated ID and cache it
        var eventWithId = event
        eventWithId.id = eventId
        
        await cacheEventsAndRelatedEntities([eventWithId])
        
        // Invalidate list caches since we have new data
        invalidateListCaches()
        
        print("💾 Cached newly created event: \(event.name)")
        return eventId
    }
    
    func updateEvent(_ event: EventItem) async throws -> EventItem {
        // Update in base repository
        let updatedEvent = try await baseRepository.updateEvent(event)
        
        // Update cache with new data
        await cacheEventsAndRelatedEntities([updatedEvent])
        
        // Invalidate list caches since event data changed
        invalidateListCaches()
        
        print("💾 Updated cached event: \(updatedEvent.name)")
        return updatedEvent
    }
    
    func updateEventMedia(eventId: String, mediaItems: [MediaItem]?) async throws {
        // Update in base repository
        try await baseRepository.updateEventMedia(eventId: eventId, mediaItems: mediaItems)
        
        // Invalidate the specific event cache so it gets refreshed with new media data
        eventCache.remove(forKey: CacheManager.CacheKeys.eventById(eventId))
        
        print("🖼️ Invalidated cache for event \(eventId) due to media update")
    }
    
    func deleteEvent(id: String) async throws {
        // Delete from base repository
        try await baseRepository.deleteEvent(id: id)
        
        // Remove from cache
        eventCache.remove(forKey: CacheManager.CacheKeys.eventById(id))
        
        // Invalidate list caches
        invalidateListCaches()
        
        print("🗑️ Removed event \(id) from cache")
    }
    
    // MARK: - Private Helper Methods
    
    /// Cache events and their related entities (authors and hosts)
    private func cacheEventsAndRelatedEntities(_ events: [EventItem]) async {
        for event in events {
            // Cache the event itself
            eventCache.set(event, forKey: CacheManager.CacheKeys.eventById(event.id))
            
            // Cache the author (User)
            userCache.set(event.author, forKey: CacheManager.CacheKeys.userById(event.author.id))
            
            // Cache the host (Gym)
            gymCache.set(event.host, forKey: CacheManager.CacheKeys.gymById(event.host.id))
        }
    }
    
    /// Invalidate all list/search caches
    private func invalidateListCaches() {
        // Remove cached lists that might now be stale
        searchCache.removeAll()
    }
}

// MARK: - Display-Optimized Methods

extension CachedEventRepository {
    
    /// Fetch events with minimal related entity data for display lists
    /// This method skips author lookup to reduce database calls
    func fetchAllEventsForDisplay() async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.allEvents()
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchAllEventsForDisplay (\(cachedEvents.count) events)")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchAllEventsForDisplay - fetching from source")
        
        // Use display-optimized method from base repository
        let events = try await baseRepository.fetchAllEventsForDisplay()
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) events for display (author lookup skipped)")
        return events
    }
    
    /// Fetch events for a gym with minimal related entity data for display
    /// This method skips author lookup to reduce database calls
    func fetchEventsForGymDisplay(gymId: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.eventsForGym(gymId)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchEventsForGymDisplay(\(gymId)) - \(cachedEvents.count) events")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchEventsForGymDisplay(\(gymId)) - fetching from source")
        
        // Use display-optimized method from base repository
        let events = try await baseRepository.fetchEventsForGymDisplay(gymId: gymId)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs for this gym
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) events for gym \(gymId) for display")
        return events
    }
    
    /// Fetch favorite events with minimal related entity data for display
    /// This method skips author lookup to reduce database calls
    func fetchFavoriteEventsForDisplay(userId: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.favoriteEvents(userId)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: fetchFavoriteEventsForDisplay(\(userId)) - \(cachedEvents.count) events")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchFavoriteEventsForDisplay(\(userId)) - fetching from source")
        
        // Use display-optimized method from base repository
        let events = try await baseRepository.fetchFavoriteEventsForDisplay(userId: userId)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of favorite event IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) favorite events for user \(userId) for display")
        return events
    }
    
    /// Search events with minimal related entity data for display
    /// This method skips author lookup to reduce database calls
    func searchEventsForDisplay(query: String) async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.eventSearch(query)
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            // Only return cached result if we have all events
            if cachedEvents.count == cachedIds.count {
                print("🎯 Cache hit: searchEventsForDisplay('\(query)') - \(cachedEvents.count) results")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: searchEventsForDisplay('\(query)') - fetching from source")
        
        // Use display-optimized method from base repository
        let events = try await baseRepository.searchEventsForDisplay(query: query)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the search result IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached search result for '\(query)': \(events.count) events for display")
        return events
    }
}

// MARK: - Section-Specific Batch Loading with Caching
extension CachedEventRepository {
    
    func fetchClassesForHomeSection() async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.sectionEvents("classes")
        
        // Try to get from cache first (shorter cache time for home sections)
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            if cachedEvents.count == cachedIds.count && !cachedIds.isEmpty {
                print("🎯 Cache hit: fetchClassesForHomeSection (\(cachedEvents.count) events)")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchClassesForHomeSection - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchClassesForHomeSection()
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs with shorter expiration for home sections
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) class events for home section")
        return events
    }
    
    func fetchFeaturedEventsForCarousel() async throws -> [EventItem] {
        let cacheKey = CacheManager.CacheKeys.sectionEvents("featured_carousel")
        
        // Try to get from cache first
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            if cachedEvents.count == cachedIds.count && !cachedIds.isEmpty {
                print("🎯 Cache hit: fetchFeaturedEventsForCarousel (\(cachedEvents.count) events)")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchFeaturedEventsForCarousel - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchFeaturedEventsForCarousel()
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) featured carousel events")
        return events
    }
    
    func fetchSocialEventsForHomeSection(userLocation: CLLocation?) async throws -> [EventItem] {
        // Create location-aware cache key
        let locationKey = userLocation != nil ? "with_location" : "no_location"
        let cacheKey = CacheManager.CacheKeys.sectionEvents("social_\(locationKey)")
        
        // Try to get from cache first (note: location-based results have shorter cache time)
        if let cachedIds = searchCache.get(forKey: cacheKey) {
            let cachedEvents = cachedIds.compactMap { eventCache.get(forKey: CacheManager.CacheKeys.eventById($0)) }
            
            if cachedEvents.count == cachedIds.count && !cachedIds.isEmpty {
                print("🎯 Cache hit: fetchSocialEventsForHomeSection (\(cachedEvents.count) events)")
                return cachedEvents
            }
        }
        
        print("🌐 Cache miss: fetchSocialEventsForHomeSection - fetching from source")
        
        // Fetch from base repository
        let events = try await baseRepository.fetchSocialEventsForHomeSection(userLocation: userLocation)
        
        // Cache individual events and related entities
        await cacheEventsAndRelatedEntities(events)
        
        // Cache the list of event IDs
        let eventIds = events.map { $0.id }
        searchCache.set(eventIds, forKey: cacheKey)
        
        print("💾 Cached \(events.count) social events for home section")
        return events
    }
}

// MARK: - Cache Management Extension

extension CachedEventRepository {
    
    /// Clear all cached event data
    func clearCache() {
        eventCache.removeAll()
        // Note: We don't clear user/gym caches as they might be used by other repositories
        
        #if DEBUG
        print("🗑️ Cleared all event cache data")
        #endif
    }
    
    /// Clear search cache only
    func clearSearchCache() {
        searchCache.removeAll()
        
        #if DEBUG
        print("🗑️ Cleared event search cache")
        #endif
    }
    
    /// Invalidate caches related to a specific gym
    func invalidateCachesForGym(gymId: String) {
        // Remove events for this gym from search cache
        searchCache.remove(forKey: CacheManager.CacheKeys.eventsForGym(gymId))
        
        // Clear all events cache since events might reference this gym
        searchCache.removeAll()
        
        #if DEBUG
        print("🚫 Invalidated event caches for gym: \(gymId)")
        #endif
    }
    
    /// Invalidate caches related to a specific user
    func invalidateCachesForUser(userId: String) {
        // Remove events for this user from search cache
        searchCache.remove(forKey: CacheManager.CacheKeys.eventsForUser(userId))
        searchCache.remove(forKey: CacheManager.CacheKeys.favoriteEvents(userId))
        
        #if DEBUG
        print("🚫 Invalidated event caches for user: \(userId)")
        #endif
    }
    
    #if DEBUG
    /// Print cache status for debugging
    func printCacheStatus() {
        print("📅 Event Cache: \(eventCache.count) items")
        print("🔍 Event Search Cache: \(searchCache.count) results")
    }
    #endif
}
