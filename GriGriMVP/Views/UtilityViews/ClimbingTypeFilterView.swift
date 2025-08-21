//
//  ClimbingTypeFilterView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 17/08/2025.
//

import SwiftUI

enum GymFilterType: String, CaseIterable {
    case all = "All"
    case boulder = "Boulder"
    case sport = "Sport"
}

struct ClimbingTypeFilterView: View {
    @Binding var selectedTypes: Set<GymFilterType>
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(GymFilterType.allCases, id: \.self) { type in
                filterTab(for: type)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func filterTab(for type: GymFilterType) -> some View {
        let isSelected = selectedTypes.contains(type)
        
        return Button(action: {
            toggleSelection(for: type)
        }) {
            Text(type.rawValue)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? AppTheme.appPrimary : AppTheme.appPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? AppTheme.appPrimary.opacity(0.1) : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(AppTheme.appPrimary, lineWidth: 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .shadow(color: AppTheme.appPrimary.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func toggleSelection(for type: GymFilterType) {
        if type == .all {
            // If "All" is selected, clear everything else and select only "All"
            selectedTypes = [.all]
        } else {
            // Remove "All" if selecting a specific type
            selectedTypes.remove(.all)
            
            // Toggle the selected type
            if selectedTypes.contains(type) {
                selectedTypes.remove(type)
                // If no specific types selected, default to "All"
                if selectedTypes.isEmpty {
                    selectedTypes = [.all]
                }
            } else {
                selectedTypes.insert(type)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTypes: Set<GymFilterType> = [.all]
        
        var body: some View {
            VStack(spacing: 24) {
                Text("Gym Filter")
                    .font(.headline)
                
                ClimbingTypeFilterView(selectedTypes: $selectedTypes)
                
                Text("Selected: \(selectedTypes.map { $0.rawValue }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
    }
    
    return PreviewWrapper()
}

