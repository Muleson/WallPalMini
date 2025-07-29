//
//  EventPageViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 29/07/2025.
//

import Foundation
import UIKit

@MainActor
class EventPageViewModel: ObservableObject {
    private let event: EventItem
    
    init(event: EventItem) {
        self.event = event
    }
    
    // MARK: - Computed Properties
    var hasMediaItems: Bool {
        guard let mediaItems = event.mediaItems else { return false }
        return !mediaItems.isEmpty
    }
    
    var mediaItems: [MediaItem] {
        return event.mediaItems ?? []
    }
    
    var formattedEventDate: String {
        let formatter = DateFormatter()
        
        // Check if event spans multiple days
        if !Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
            // Multi-day event: show date range
            formatter.dateFormat = "MMM d"
            let startDate = formatter.string(from: event.startDate)
            let endDate = formatter.string(from: event.endDate)
            return "\(startDate) - \(endDate)"
        } else {
            // Single day event: show just the date
            formatter.dateStyle = .medium
            return formatter.string(from: event.startDate)
        }
    }
    
    var formattedTimeAndDuration: String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let startTime = timeFormatter.string(from: event.startDate)
        
        // Check if event spans multiple days
        if !Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
            // Multi-day event: show time on start date
            return startTime
        } else {
            // Single day event: show start time and duration
            let duration = event.endDate.timeIntervalSince(event.startDate)
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if hours > 0 && minutes > 0 {
                return "\(startTime) - \(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(startTime) - \(hours)h"
            } else if minutes > 0 {
                return "\(startTime) - \(minutes)m"
            } else {
                return startTime
            }
        }
    }
    
    // MARK: - Actions
    func openMaps() {
        guard !event.location.isEmpty else { return }
        
        // Create the maps URL with the location
        let encodedLocation = event.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapsURLString = "http://maps.apple.com/?q=\(encodedLocation)"
        
        // Try to open Apple Maps first
        if let mapsURL = URL(string: mapsURLString) {
            UIApplication.shared.open(mapsURL) { success in
                if !success {
                    // Fallback to Google Maps web if Apple Maps fails
                    let googleMapsURLString = "https://www.google.com/maps/search/?api=1&query=\(encodedLocation)"
                    if let googleURL = URL(string: googleMapsURLString) {
                        UIApplication.shared.open(googleURL)
                    }
                }
            }
        }
    }
    
    func handleRegistration() {
        guard event.registrationRequired,
              let registrationLink = event.registrationLink,
              let url = URL(string: registrationLink) else { return }
        
        UIApplication.shared.open(url)
    }
}
