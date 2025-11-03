//
//  GymVisitDialog.swift
//  GriGriMVP
//
//  Created by Sam Quested on 17/08/2025.
//

import SwiftUI

struct GymVisitDialog: ViewModifier {
    @Binding var isPresented: Bool
    let gym: Gym?
    let onViewInMaps: () -> Void
    let onViewProfile: () -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("Visit Gym", isPresented: $isPresented) {
                if let gym = gym {
                    Button("View in Maps") {
                        onViewInMaps() 
                    }
                    Button("View Gym Profile") { 
                        onViewProfile() 
                    }
                    Button("Cancel", role: .cancel) { 
                        isPresented = false
                    }
                }
            } message: {
                if let gym = gym {
                    Text("How would you like to visit \(gym.name)?")
                }
            }
    }
}

extension View {
    func gymVisitDialog(
        isPresented: Binding<Bool>,
        gym: Gym?,
        onViewInMaps: @escaping () -> Void,
        onViewProfile: @escaping () -> Void
    ) -> some View {
        modifier(GymVisitDialog(
            isPresented: isPresented,
            gym: gym,
            onViewInMaps: onViewInMaps,
            onViewProfile: onViewProfile
        ))
    }
}
