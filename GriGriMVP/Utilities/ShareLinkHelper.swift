//
//  ShareLinkHelper.swift
//  GriGriMVP
//
//  Created by Sam Quested on 07/10/2025.
//

import SwiftUI

/// Helper to generate shareable deep links and present the iOS share sheet
struct ShareLinkHelper {

    // MARK: - Deep Link Generation

    /// Generate a deep link URL for an event
    static func eventDeepLink(eventId: String) -> URL {
        // Use custom URL scheme for reliability
        return URL(string: "crahg://event/\(eventId)")!
    }

    /// Generate a deep link URL for a gym
    static func gymDeepLink(gymId: String) -> URL {
        // Use custom URL scheme for reliability
        return URL(string: "crahg://gym/\(gymId)")!
    }

    /// Generate a universal link URL for an event (web fallback)
    static func eventUniversalLink(eventId: String) -> URL {
        return URL(string: "https://crahg.app/events/\(eventId)")!
    }

    /// Generate a universal link URL for a gym (web fallback)
    static func gymUniversalLink(gymId: String) -> URL {
        return URL(string: "https://crahg.app/gyms/\(gymId)")!
    }

    // MARK: - Share Message Generation

    /// Generate a shareable message for an event
    static func eventShareMessage(event: EventItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let dateString = formatter.string(from: event.startDate)
        return """
        Check out this event on Crahg!

        \(event.name)
        📍 \(event.host.name)
        📅 \(dateString)
        """
    }

    /// Generate a shareable message for a gym
    static func gymShareMessage(gym: Gym) -> String {
        return """
        Check out this gym on Crahg!

        \(gym.name)
        """
    }

    // MARK: - Share Sheet Items

    /// Create share items for an event (message + deep link)
    static func eventShareItems(event: EventItem) -> [Any] {
        let message = eventShareMessage(event: event)
        let deepLink = eventDeepLink(eventId: event.id)
        return [message, deepLink]
    }

    /// Create share items for a gym (message + deep link)
    static func gymShareItems(gym: Gym) -> [Any] {
        let message = gymShareMessage(gym: gym)
        let deepLink = gymDeepLink(gymId: gym.id)
        return [message, deepLink]
    }
}

// MARK: - iOS Share Sheet View Modifier

/// View modifier to present the iOS share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude non-social sharing options
        controller.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .markupAsPDF,
            .openInIBooks,
            .print,
            .saveToCameraRoll
        ]

        // Configure for iPad popover presentation
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first
            popover.permittedArrowDirections = []
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - SwiftUI Extension

extension View {
    /// Present the iOS share sheet with the given items as a half sheet
    func shareSheet(isPresented: Binding<Bool>, activityItems: [Any]) -> some View {
        sheet(isPresented: isPresented) {
            ShareSheet(activityItems: activityItems)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
