//
//  HoursCardViews.swift
//  GriGriMVP
//
//  Created by Sam Quested on 03/10/2025.
//

import SwiftUI

// MARK: - Main Hours Card Container
struct GymHoursCard: View {
    let hours: GymOperatingHours
    @State private var scrollToToday = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Opening Hours")
                    .font(.appSubheadline)
                    .foregroundStyle(AppTheme.appTextPrimary)
                
                Spacer()
                
                if hours.isCurrentlyOpen() {
                    CurrentStatusBadge(isOffPeak: hours.isCurrentlyOffPeak())
                }
            }
            .padding(.horizontal)
            
            // Horizontal scrolling day cards
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 12) {
                        ForEach(orderedDays, id: \.day) { dayInfo in
                            DayHoursCard(
                                day: dayInfo.day,
                                dayHours: dayInfo.hours,
                                isToday: dayInfo.isToday
                            )
                            .id(dayInfo.day)
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        // Scroll to today's card on appear
                        if let todayDay = orderedDays.first?.day {
                            proxy.scrollTo(todayDay, anchor: .leading)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    // Helper to get days ordered from today
    private var orderedDays: [(day: String, hours: GymOperatingHours.DayHours?, isToday: Bool)] {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        
        let allDays = [
            (day: "Sunday", hours: hours.sunday, weekday: 1),
            (day: "Monday", hours: hours.monday, weekday: 2),
            (day: "Tuesday", hours: hours.tuesday, weekday: 3),
            (day: "Wednesday", hours: hours.wednesday, weekday: 4),
            (day: "Thursday", hours: hours.thursday, weekday: 5),
            (day: "Friday", hours: hours.friday, weekday: 6),
            (day: "Saturday", hours: hours.saturday, weekday: 7)
        ]
        
        // Reorder so today is first
        let todayIndex = allDays.firstIndex { $0.weekday == today } ?? 0
        let reordered = Array(allDays[todayIndex...]) + Array(allDays[..<todayIndex])
        
        return reordered.map { (day: $0.day, hours: $0.hours, isToday: $0.weekday == today) }
    }
}

// MARK: - Current Status Badge
struct CurrentStatusBadge: View {
    let isOffPeak: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Open Now")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if isOffPeak {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("Off-Peak")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Individual Day Hours Card
struct DayHoursCard: View {
    let day: String
    let dayHours: GymOperatingHours.DayHours?
    let isToday: Bool
    @State private var isExpanded = false
    
    var body: some View {
        Group {
            if dayHours?.hasOffPeakTimes == true {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day name with optional expand icon and Today tag
            HStack(alignment: .top) {
                Text(day.prefix(3).uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? AppTheme.appPrimary : .secondary)
                
                Spacer()
                
                // Today indicator in top right
                if isToday {
                    Text("Today")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.appPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.appPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if dayHours?.hasOffPeakTimes == true {
                    Image(systemName: isExpanded ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.appPrimary)
                }
            }
            
            // Hours display
            if let hours = dayHours {
                if hours.isClosed {
                    Text("Closed")
                        .font(.appBody)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        // Main hours
                        HStack(spacing: 2) {
                            Text(formatTime(hours.open))
                                .font(.appBody)
                                .fontWeight(.medium)
                            Text("—")
                                .font(.appBody)
                                .foregroundColor(.secondary)
                            Text(formatTime(hours.close))
                                .font(.appBody)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.appTextPrimary)
                        
                        // Off-peak periods (shown when expanded)
                        if isExpanded && hours.hasOffPeakTimes {
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Off-Peak")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                
                                ForEach(hours.offPeakPeriods) { period in
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                        
                                        Text("\(formatTime(period.startTime)) — \(formatTime(period.endTime))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        }
                    }
                }
            } else {
                Text("—")
                    .font(.appBody)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(width: isExpanded ? 220 : 160, alignment: .leading)
        .frame(height: isExpanded ? 140 : 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.appContentBG)
                .shadow(color: Color.black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isToday ? AppTheme.appPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func formatTime(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let date = formatter.date(from: time) else {
            return time
        }
        
        formatter.dateFormat = "h:mm a"
        let formattedTime = formatter.string(from: date)
        
        // Remove leading zero for single digit hours
        if formattedTime.hasPrefix("0") {
            return String(formattedTime.dropFirst())
        }
        
        return formattedTime
    }
}

// MARK: - Previews
#Preview("With Off-Peak Times") {
    let sampleHours = GymOperatingHours(
        monday: .init(
            open: "06:00",
            close: "22:00",
            offPeakPeriods: [
                .init(startTime: "06:00", endTime: "09:00"),
                .init(startTime: "14:00", endTime: "17:00")
            ]
        ),
        tuesday: .init(
            open: "06:00",
            close: "22:00",
            offPeakPeriods: [
                .init(startTime: "06:00", endTime: "09:00")
            ]
        ),
        wednesday: .init(open: "06:00", close: "22:00"),
        thursday: .init(open: "06:00", close: "22:00"),
        friday: .init(open: "06:00", close: "23:00"),
        saturday: .init(open: "08:00", close: "20:00"),
        sunday: .init(open: "08:00", close: "20:00")
    )
    
    ScrollView {
        VStack {
            GymHoursCard(hours: sampleHours)
        }
        .padding()
    }
    .background(AppTheme.appBackgroundBG)
}

#Preview("Without Off-Peak Times") {
    let sampleHours = GymOperatingHours(
        monday: .init(open: "06:00", close: "22:00"),
        tuesday: .init(open: "06:00", close: "22:00"),
        wednesday: .init(open: "06:00", close: "22:00"),
        thursday: .init(open: "06:00", close: "22:00"),
        friday: .init(open: "06:00", close: "23:00"),
        saturday: .init(open: "08:00", close: "20:00"),
        sunday: .init(open: "08:00", close: "20:00", isClosed: false)
    )
    
    ScrollView {
        VStack {
            GymHoursCard(hours: sampleHours)
        }
        .padding()
    }
    .background(AppTheme.appBackgroundBG)
}

#Preview("Single Day Card - Today with Off-Peak") {
    let hours = GymOperatingHours.DayHours(
        open: "06:00",
        close: "22:00",
        offPeakPeriods: [
            .init(startTime: "06:00", endTime: "09:00"),
            .init(startTime: "14:00", endTime: "17:00")
        ]
    )
    
    return DayHoursCard(day: "Monday", dayHours: hours, isToday: true)
        .padding()
        .background(AppTheme.appBackgroundBG)
}

#Preview("Single Day Card - Closed") {
    let hours = GymOperatingHours.DayHours(
        open: "00:00",
        close: "00:00",
        isClosed: true
    )
    
    return DayHoursCard(day: "Sunday", dayHours: hours, isToday: false)
        .padding()
        .background(AppTheme.appBackgroundBG)
}
