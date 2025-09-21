//
//  FilterBottomSheetView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 02/09/2025.
//

import SwiftUI

struct FilterBottomSheetView: View {
    @Binding var selectedEventTypes: Set<EventType>
    @Binding var selectedClimbingTypes: Set<ClimbingTypes>
    @Binding var proximityFilter: UpcomingViewModel.ProximityFilter
    @Environment(\.dismiss) private var dismiss
    
    // Callback to handle navigation to FilteredEventsView
    let onApplyFilters: () -> Void
    
    // Computed property to check if any filters are active
    private var hasActiveFilters: Bool {
        !selectedEventTypes.isEmpty || 
        !selectedClimbingTypes.isEmpty || 
        proximityFilter != .all
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Filter Events")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.appTextPrimary)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        selectedEventTypes.removeAll()
                        selectedClimbingTypes.removeAll()
                        proximityFilter = .all
                    }
                    .foregroundColor(AppTheme.appPrimary)
                    .font(.appBody)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Event Type Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Event Type")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                                ForEach(EventType.allCases, id: \.self) { eventType in
                                    FilterChip(
                                        title: eventType.displayName,
                                        isSelected: selectedEventTypes.contains(eventType)
                                    ) {
                                        if selectedEventTypes.contains(eventType) {
                                            selectedEventTypes.remove(eventType)
                                        } else {
                                            selectedEventTypes.insert(eventType)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Climbing Type Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Climbing Type")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                                ForEach(ClimbingTypes.allCases.sortedForDisplay(), id: \.self) { climbingType in
                                    FilterChip(
                                        title: climbingType.rawValue.capitalized,
                                        isSelected: selectedClimbingTypes.contains(climbingType)
                                    ) {
                                        if selectedClimbingTypes.contains(climbingType) {
                                            selectedClimbingTypes.remove(climbingType)
                                        } else {
                                            selectedClimbingTypes.insert(climbingType)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Proximity Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Distance")
                                .font(.appHeadline)
                                .foregroundColor(AppTheme.appTextPrimary)
                            
                            VStack(spacing: 6) {
                                ForEach(UpcomingViewModel.ProximityFilter.allCases, id: \.self) { proximity in
                                    FilterChip(
                                        title: proximity.displayName,
                                        isSelected: proximityFilter == proximity,
                                        style: .radio
                                    ) {
                                        proximityFilter = proximity
                                    }
                                }
                            }
                        }
                        
                        // Add extra padding at bottom for floating button
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            
            // Floating Apply Button
            if hasActiveFilters {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                        onApplyFilters()
                    }) {
                        HStack {
                            Text("Apply Filters")
                                .font(.appBody)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.appPrimary)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: AppTheme.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let style: FilterChipStyle
    let action: () -> Void
    
    init(title: String, isSelected: Bool, style: FilterChipStyle = .checkbox, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.appBody)
                    .foregroundColor(isSelected ? AppTheme.appPrimary : AppTheme.appTextPrimary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppTheme.appPrimary.opacity(0.15) : AppTheme.appContentBG)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? AppTheme.appPrimary : AppTheme.appTextLight.opacity(0.3), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum FilterChipStyle {
    case checkbox
    case radio
}

#Preview {
    FilterBottomSheetView(
        selectedEventTypes: .constant([.gymClass, .social]),
        selectedClimbingTypes: .constant([.bouldering]),
        proximityFilter: .constant(.withinFiveKm),
        onApplyFilters: {
            print("Apply filters tapped")
        }
    )
}
