//
//  PassViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import Foundation
import UIKit
import Combine
import SwiftUI

@MainActor
class PassDisplayViewModel: ObservableObject {
    // MARK: - Display Properties Only
    @Published var deletionState: DeletionState<Pass> = .none
    @Published var gyms: [String: Gym] = [:] // Cache for gym lookups
    
    private let passManager = PassManager.shared
    private let gymRepository: GymRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository()) {
        self.gymRepository = gymRepository
        
        // Subscribe to changes in the shared passManager's passes array
        passManager.$passes.sink { [weak self] passes in
            print("🔄 PassDisplayViewModel: Passes changed, count: \(passes.count)")
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                // Also reload gyms when passes change to ensure we have gym data for newly added passes
                print("🔄 PassDisplayViewModel: Triggering gym reload for passes")
                self?.loadGymsForPasses()
            }
        }.store(in: &cancellables)
        
        // Load gyms for passes
        loadGymsForPasses()
    }

    // Keep the existing computed properties
    var passes: [Pass] {
        let allPasses = passManager.passes
        print("🔍 All passes in manager: \(allPasses.count)")
        let nonPrimary = allPasses.filter { !$0.isActive }
        print("🔍 Non-primary passes: \(nonPrimary.count)")
        return nonPrimary
    }
    
    var primaryPass: Pass? {
        let primary = passManager.passes.first(where: { $0.isActive })
        print("🔍 Primary pass: \(primary?.mainInformation.title ?? "None")")
        return primary
    }
    
    // Add this new computed property for all passes
    var allPasses: [Pass] {
        return passManager.passes
    }
    
    // Method to get gym for a pass
    func gym(for pass: Pass) -> Gym? {
        guard let gymId = pass.gymId else { 
            return nil
        }
        let gym = gyms[gymId]
        
        return gym
    }
    
    // Load gyms for all passes
    private func loadGymsForPasses() {
        let gymIds = Set(passManager.passes.compactMap { $0.gymId })
        print("🏋️‍♂️ PassDisplayViewModel: Loading gyms for \(gymIds.count) unique gym IDs: \(gymIds)")
        
        Task { [weak self] in
            guard let self = self else { return }
            var didLoadNewGymData = false
            
            for gymId in gymIds {
                if gyms[gymId] == nil {
                    let gym = try await gymRepository.getGym(id: gymId)
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        gyms[gymId] = gym
                        didLoadNewGymData = true
                    }
                }
            }
            
            // Trigger another UI update if we loaded new gym data
            if didLoadNewGymData {
                print("🔄 PassDisplayViewModel: Triggering UI update after loading new gym data")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.objectWillChange.send()
                }
            }
        }
    }

    // MARK: - Pass Display Logic
    
    func loadPasses() {
        // Force a refresh by triggering objectWillChange
        print("🔄 LoadPasses called - triggering refresh")
        objectWillChange.send()
    }
    
    func setActivePass(for passID: UUID) {
        passManager.setActivePass(id: passID)
    }
    
    // MARK: - Pass Deletion Logic
    
    func confirmDelete(for pass: Pass) {
        deletionState = .confirming(pass)
    }
    
    func cancelDelete() {
        deletionState = .none
    }
    
    func handleDelete(for pass: Pass) {
        if case let .confirming(pass) = deletionState {
            passManager.delete(id: pass.id, wasItemPrimary: pass.isActive)
            deletionState = .none
        }
    }
    
    // MARK: - Pass Management
    
    func updatePassTitle(for passID: UUID, with title: String) {
        passManager.updatePassTitle(for: passID, with: title)
    }
    
    // MARK: - Barcode Generation (for display)
    
    func generateBarcodeImage(from pass: Pass) -> UIImage? {
        return PassBarcodeGenerator.generateImage(from: pass)
    }
    
    func generatePreviewBarcodeImage(from pass: Pass, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        return PassBarcodeGenerator.generatePreviewImage(from: pass, size: size)
    }
    
    func generateScanningBarcodeImage(from pass: Pass) -> UIImage? {
        return PassBarcodeGenerator.generateScanningImage(from: pass)
    }
    
    func canGenerateBarcode(for pass: Pass) -> Bool {
        return PassBarcodeGenerator.isValidBarcodeType(pass.barcodeData.codeType)
    }
}
