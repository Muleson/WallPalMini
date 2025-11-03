//
//  PrimaryPassViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/09/2025.
//

import Foundation
import Combine

@MainActor
class PrimaryPassViewModel: ObservableObject {
    @Published var primaryPass: Pass?
    
    private let passManager = PassManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Only observe changes to the primary pass specifically
        passManager.$passes
            .map { passes in passes.first(where: { $0.isActive }) }
            .removeDuplicates { oldPass, newPass in
                // Only update if the primary pass actually changed
                oldPass?.id == newPass?.id
            }
            .assign(to: \.primaryPass, on: self)
            .store(in: &cancellables)
    }
}
