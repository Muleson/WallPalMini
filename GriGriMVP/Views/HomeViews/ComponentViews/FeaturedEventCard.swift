//
//  FeaturedEventCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct FeaturedEventCard: View {
    let event: EventItem
    let onView: () -> Void
    let onRegister: () -> Void
    
    private var eventDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: event.startDate)
    }
    
    private var eventTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        let startTime = formatter.string(from: event.startDate)
        
        // Show range with end date
        let endTime = formatter.string(from: event.endDate)
        return "\(startTime) - \(endTime)"
    }
    
    private var backgroundGradient: LinearGradient {
        // Choose gradient based on event type or use random attractive gradients
        let gradients: [LinearGradient] = [
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ]
        
        // Use event ID to consistently pick the same gradient for the same event
        let index = abs(event.id.hashValue) % gradients.count
        return gradients[index]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Event banner section - portrait orientation on left
            Rectangle()
                .fill(backgroundGradient)
                .frame(width: 160, height: 240)
                .overlay(
                    eventBannerContent
                )
            
            // Event details section - text content on right
            eventDetailsSection
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var eventBannerContent: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                // Event type icon at top
                Image(systemName: climbingIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
                
                Spacer()
                
                // Event name styled as banner text
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(event.name.components(separatedBy: " ").chunked(into: 1), id: \.self) { chunk in
                        Text(chunk.joined(separator: " ").uppercased())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Host/venue info
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.appTextLight)
                
                Text(event.host.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .lineLimit(1)
            }
            
            // Date
            Text(eventDateFormatted)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.appTextPrimary)
                .lineLimit(1)
            
            // Time
            Text(eventTimeFormatted)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.appTextLight)
            
            // Event type tag
            HStack {
                Text(event.type.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tagBackgroundColor)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            Spacer()
            
            // Action buttons - stacked vertically for better fit
            VStack(spacing: 8) {
                Button(action: onView) {
                    Text("View")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.appPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.appPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: onRegister) {
                    Text("Register")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: AppTheme.appPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(16)
        .frame(height: 240)
        .background(Color(AppTheme.appContentBG))
    }
    
    private var climbingIcon: String {
        // Choose icon based on event type
        switch event.type {
        case .competition:
            return "trophy.fill"
        case .social:
            return "person.3.fill"
        case .openDay:
            return "door.left.hand.open"
        case .settingTaster:
            return "hammer.fill"
        case .opening:
            return "party.popper.fill"
        }
    }
    
    private var tagBackgroundColor: Color {
        switch event.type {
        case .competition:
            return Color.yellow.opacity(0.2)
        case .social:
            return Color.green.opacity(0.2)
        case .openDay:
            return Color.blue.opacity(0.2)
        case .settingTaster:
            return Color.purple.opacity(0.2)
        case .opening:
            return Color.orange.opacity(0.2)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Preview with different event types from sample data
        FeaturedEventCard(
            event: SampleData.events[0], // Summer Send Festival (competition)
            onView: {
                print("View event: \(SampleData.events[0].name)")
            },
            onRegister: {
                print("Register for: \(SampleData.events[0].name)")
            }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
