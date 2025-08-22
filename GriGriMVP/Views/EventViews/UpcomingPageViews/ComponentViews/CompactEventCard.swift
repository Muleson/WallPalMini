//
//  CompactEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/08/2025.
//

import SwiftUI

struct CompactEventCard: View {
    let event: EventItem
    let onTap: () -> Void
    var onGymTap: ((Gym) -> Void)? = nil
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Host/venue info with small profile image - similar to HomeFeaturedEventCard
                Button(action: {
                    onGymTap?(event.host)
                }) {
                    HStack(spacing: 4) {
                        AsyncImage(url: event.host.profileImage?.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(AppTheme.appTextLight.opacity(0.3))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(AppTheme.appTextLight)
                                )
                        }
                        
                        Text(event.host.name)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.appPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Event name
                Text(event.name)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Date
                Text(eventDateFormatted)
                    .font(.system(size: 13, weight: .light, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                
                // Time (or frequency for recurring events)
                Text(eventTimeFormatted)
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundColor(AppTheme.appTextLight)
                
                Spacer()
                
                // Primary action button
                PrimaryActionButton.custom("View", style: .primary, size: .compact) {
                    onTap()
                }
            }
            .padding(10)
            .frame(width: 180, height: 170)
            .background(Color(AppTheme.appContentBG))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .appCardShadow()
        }
    .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Date/Time Formatting
    
    /// Returns formatted date for compact event cards - day name for recurring events, date for one-off events
    private var eventDateFormatted: String {
        let formatter = DateFormatter()
        
        if event.frequency != nil {
            // For recurring events, show the day of the week with time
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let day = dayFormatter.string(from: event.startDate)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mma"
            let time = timeFormatter.string(from: event.startDate)
            
            return "\(day) @ \(time)"
        } else {
            // For one-off events, show the date
            formatter.dateFormat = "MMM d"
            return formatter.string(from: event.startDate)
        }
    }
    
    /// Returns formatted time for compact event cards - frequency timing for recurring events, time for one-off events
    private var eventTimeFormatted: String {
        if let frequency = event.frequency {
            // For recurring events, show the frequency timing
            return frequency.displayName
        } else {
            // For one-off events, show the actual time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            return formatter.string(from: event.startDate)
        }
    }
}


#Preview {
    VStack(spacing: 12) {
        CompactEventCard(event: SampleData.events[8]) {
            print("Tapped event: \(SampleData.events[8].name)")
        }
        
        CompactEventCard(event: SampleData.events[6]) {
            print("Tapped event: \(SampleData.events[6].name)")
        }
        
        CompactEventCard(event: SampleData.events[9]) {
            print("Tapped event: \(SampleData.events[9].name)")
        }
        
        CompactEventCard(event: SampleData.events[3]) {
            print("Tapped event: \(SampleData.events[3].name)")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

