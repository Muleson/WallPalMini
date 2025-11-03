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
    @Published var companies: [String: GymCompany] = [:] // Cache for company lookups
    @Published private var pendingDeletions: Set<UUID> = [] // Track passes awaiting deletion confirmation
    
    private let passManager = PassManager.shared
    private let gymRepository: GymRepositoryProtocol
    private let gymCompanyRepository: GymCompanyRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         gymCompanyRepository: GymCompanyRepositoryProtocol = RepositoryFactory.createGymCompanyRepository()) {
        self.gymRepository = gymRepository
        self.gymCompanyRepository = gymCompanyRepository
        
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
        let allPasses = passManager.passes.filter { !pendingDeletions.contains($0.id) }
        print("🔍 All passes in manager: \(allPasses.count)")
        let nonPrimary = allPasses.filter { !$0.isActive }
        print("🔍 Non-primary passes: \(nonPrimary.count)")
        return nonPrimary
    }
    
    var primaryPass: Pass? {
        let primary = passManager.passes
            .filter { !pendingDeletions.contains($0.id) }
            .first(where: { $0.isActive })
        print("🔍 Primary pass: \(primary?.mainInformation.title ?? "None")")
        return primary
    }
    
    // Add this new computed property for all passes
    var allPasses: [Pass] {
        return passManager.passes.filter { !pendingDeletions.contains($0.id) }
    }
    
    // Method to get gym for a pass
    func gym(for pass: Pass) -> Gym? {
        guard let gymId = pass.gymId else { 
            return nil
        }
        let gym = gyms[gymId]
        
        return gym
    }
    
    // Method to get company for a pass
    func company(for pass: Pass) -> GymCompany? {
        guard let companyId = pass.gymCompanyId else {
            return nil
        }
        return companies[companyId]
    }
    
    // Method to get display name for a pass (company name or gym name)
    func displayName(for pass: Pass) -> String {
        if let company = company(for: pass) {
            return company.name
        } else if let gym = gym(for: pass) {
            return gym.name
        } else {
            return pass.mainInformation.title
        }
    }
    
    // Load gyms and companies for all passes
    private func loadGymsForPasses() {
        let gymIds = Set(passManager.passes.compactMap { $0.gymId })
        let companyIds = Set(passManager.passes.compactMap { $0.gymCompanyId })
        print("🏋️‍♂️ PassDisplayViewModel: Loading gyms for \(gymIds.count) unique gym IDs: \(gymIds)")
        print("🏢 PassDisplayViewModel: Loading companies for \(companyIds.count) unique company IDs: \(companyIds)")
        
        Task { [weak self] in
            guard let self = self else { return }
            var didLoadNewData = false
            
            // Load gyms
            for gymId in gymIds {
                if gyms[gymId] == nil {
                    let gym = try await gymRepository.getGym(id: gymId)
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        gyms[gymId] = gym
                        didLoadNewData = true
                    }
                    
                    // Cache gym image locally for stable rendering
                    if let profileImageURL = gym?.profileImage?.url {
                        let result = await LocalImageCache.shared.cacheImage(for: gymId, from: profileImageURL)
                        if case .failure(let error) = result {
                            print("⚠️ Failed to cache gym image for \(gymId): \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            // Load companies
            for companyId in companyIds {
                if companies[companyId] == nil {
                    let company = try await gymCompanyRepository.getCompany(id: companyId)
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        companies[companyId] = company
                        didLoadNewData = true
                    }
                    
                    // Cache company image locally for stable rendering
                    if let profileImageURL = company?.profileImage?.url {
                        let result = await LocalImageCache.shared.cacheImage(for: companyId, from: profileImageURL)
                        if case .failure(let error) = result {
                            print("⚠️ Failed to cache company image for \(companyId): \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            // Trigger another UI update if we loaded new data
            if didLoadNewData {
                print("🔄 PassDisplayViewModel: Triggering UI update after loading new data")
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
        // Mark as pending deletion to hide from UI immediately
        pendingDeletions.insert(pass.id)
        deletionState = .confirming(pass)
    }
    
    func cancelDelete() {
        // Remove from pending deletions if cancelled
        if case let .confirming(pass) = deletionState {
            pendingDeletions.remove(pass.id)
        }
        deletionState = .none
    }
    
    func handleDelete(for pass: Pass) {
        // Actually delete the pass
        passManager.delete(id: pass.id, wasItemPrimary: pass.isActive)
        pendingDeletions.remove(pass.id)
        deletionState = .none
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
