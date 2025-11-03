//
//  SocialEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/08/2025.
//


//
//  Created by Sam Quested on 21/08/2025.
//

import SwiftUI

struct SocialEventCard: View {
    let event: EventItem
    let onTap: () -> Void
    var onGymTap: ((Gym) -> Void)? = nil
    var onEventTap: ((EventItem) -> Void)? = nil
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Top row: Host info and primary View button
                HStack(alignment: .center) {
                    Button(action: {
                        onGymTap?(event.host)
                    }) {
                        HStack(spacing: 6) {
                            CachedGymImageView(gym: event.host, size: 16)

                            Text(event.host.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.appPrimary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }

                // Event name
                Text(event.name)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .lineLimit(2)

                // Date and time info
                dateTimeSection

                    // Event description (below date/time) — show up to 2 lines with inline 'See more'
                    if !event.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // TODO: Re-enable "See more" functionality when fixed
                        /*
                        if shouldShowSeeMore {
                            Button(action: { onEventTap?(event) }) {
                                Text(event.description) +
                                Text(" See more")
                                    .foregroundColor(AppTheme.appPrimary)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .font(.system(size: 13, weight: .light, design: .rounded))
                            .foregroundColor(AppTheme.appTextLight)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(event.description)
                                .font(.system(size: 13, weight: .light, design: .rounded))
                                .foregroundColor(AppTheme.appTextLight)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        */
                        
                        // Simplified description display without "See more" functionality
                        Text(event.description)
                            .font(.system(size: 13, weight: .light, design: .rounded))
                            .foregroundColor(AppTheme.appTextLight)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

            }
                .padding(AppTheme.Spacing.cardPadding)
                .frame(width: 280)
            .background(AppTheme.appContentBG)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .appCardShadow()
        }
    .buttonStyle(PlainButtonStyle())
    .padding(.vertical, 4)
    }
    
    // MARK: - Helper Properties
    
    // TODO: Re-enable when "See more" functionality is fixed
    /*
    private var shouldShowSeeMore: Bool {
        // Simple heuristic: if description is longer than ~80 characters, it likely needs truncation
        // This is approximate since we can't easily measure exact text layout
        return event.description.count > 80
    }
    */
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eventDateFormatted)
                .font(.system(size: 13, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
            
            Text(eventTimeFormatted)
                .font(.system(size: 12, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.appTextLight)
        }
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
    ScrollView {
        VStack(spacing: 16) {
            // Example with a description
            SocialEventCard(event: SampleData.events[8]) {
                print("Tapped event: \(SampleData.events[1].name)")
            }
            
            // Example with a longer description
            SocialEventCard(event: SampleData.events[9]) {
                print("Tapped event: \(SampleData.events[4].name)")
            }
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
