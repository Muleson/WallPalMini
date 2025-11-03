//
//  DeepLinkManager.swift
//  GriGriMVP
//
//  Created by Sam Quested on 07/10/2025.
//

import Foundation
import SwiftUI

/// Represents the different types of deep links the app can handle
enum DeepLinkDestination: Equatable {
    case home
    case event(id: String)
    case gym(id: String)
    case passes
    case whatsOn
    case gyms
}

/// Manages deep linking from web URLs and custom URL schemes
@MainActor
class DeepLinkManager: ObservableObject {
    @Published var pendingDeepLink: DeepLinkDestination?

    /// Parse a URL and return the appropriate deep link destination
    func handleURL(_ url: URL) -> DeepLinkDestination? {
        // Handle custom URL scheme: crahg://
        if url.scheme == "crahg" {
            return parseCustomSchemeURL(url)
        }

        // Handle universal links: https://crahg.app/...
        if url.host == "crahg.app" || url.host == "www.crahg.app" {
            return parseUniversalLinkURL(url)
        }

        return nil
    }

    /// Parse custom URL scheme (crahg://...)
    private func parseCustomSchemeURL(_ url: URL) -> DeepLinkDestination? {
        let path = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // Handle: crahg://event/{id}
        if path == "event", let eventId = pathComponents.first {
            return .event(id: eventId)
        }

        // Handle: crahg://gym/{id}
        if path == "gym", let gymId = pathComponents.first {
            return .gym(id: gymId)
        }

        // Handle: crahg://home
        if path == "home" {
            return .home
        }

        // Handle: crahg://passes
        if path == "passes" {
            return .passes
        }

        // Handle: crahg://whats-on or crahg://whatson
        if path == "whats-on" || path == "whatson" {
            return .whatsOn
        }

        // Handle: crahg://gyms
        if path == "gyms" {
            return .gyms
        }

        return nil
    }

    /// Parse universal link (https://crahg.app/...)
    private func parseUniversalLinkURL(_ url: URL) -> DeepLinkDestination? {
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard !pathComponents.isEmpty else {
            return .home
        }

        let firstComponent = pathComponents[0]

        // Handle: https://crahg.app/events/{id}
        if firstComponent == "events", pathComponents.count > 1 {
            let eventId = pathComponents[1]
            return .event(id: eventId)
        }

        // Handle: https://crahg.app/gyms/{id}
        if firstComponent == "gyms", pathComponents.count > 1 {
            let gymId = pathComponents[1]
            return .gym(id: gymId)
        }

        // Handle: https://crahg.app/home
        if firstComponent == "home" {
            return .home
        }

        // Handle: https://crahg.app/passes
        if firstComponent == "passes" {
            return .passes
        }

        // Handle: https://crahg.app/whats-on
        if firstComponent == "whats-on" {
            return .whatsOn
        }

        // Handle: https://crahg.app/gyms (list)
        if firstComponent == "gyms" && pathComponents.count == 1 {
            return .gyms
        }

        return nil
    }

    /// Store a deep link to be processed later (e.g., after authentication)
    func setPendingDeepLink(_ destination: DeepLinkDestination) {
        pendingDeepLink = destination
    }

    /// Clear the pending deep link
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
}
