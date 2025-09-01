//
//  CachedItem.swift
//  GriGriMVP
//
//  Created by Sam Quested on 01/09/2025.
//

import Foundation

/// A wrapper for cached items that tracks timestamps and expiration
public struct CachedItem<T> {
    public let value: T
    public let cachedAt: Date
    public let timeToLive: TimeInterval
    
    /// The absolute expiration time for this cached item
    public var expiresAt: Date {
        return cachedAt.addingTimeInterval(timeToLive)
    }
    
    /// Whether this cached item has expired
    public var isExpired: Bool {
        return Date() > expiresAt
    }
    
    /// Remaining time until expiration (negative if already expired)
    public var timeUntilExpiration: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
    
    public init(value: T, timeToLive: TimeInterval) {
        self.value = value
        self.cachedAt = Date()
        self.timeToLive = timeToLive
    }
}

// MARK: - Equatable and Hashable conformance where T conforms
extension CachedItem: Equatable where T: Equatable {
    public static func == (lhs: CachedItem<T>, rhs: CachedItem<T>) -> Bool {
        return lhs.value == rhs.value && lhs.cachedAt == rhs.cachedAt
    }
}

extension CachedItem: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(cachedAt)
    }
}
