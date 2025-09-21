//
//  ClimbingTypeOrdering.swift
//  GriGriMVP
//
//  Created by Sam Quested on 17/09/2025.
//

import Foundation

extension ClimbingTypes {
    /// Defines the standard display order for climbing types
    /// Order: Sport, Bouldering, Board, Gym
    private static let displayOrder: [ClimbingTypes] = [.sport, .bouldering, .board, .gym]
    
    /// Returns the sort priority for this climbing type
    var sortOrder: Int {
        return Self.displayOrder.firstIndex(of: self) ?? Int.max
    }
}

extension Array where Element == ClimbingTypes {
    /// Returns climbing types sorted in the standard display order
    /// Order: Sport, Bouldering, Board, Gym
    func sortedForDisplay() -> [ClimbingTypes] {
        return self.sorted { $0.sortOrder < $1.sortOrder }
    }
}
