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
    
    private let passManager = PassManager.shared
    private var cancellables = Set<AnyCancellable>()
    
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
    
    init() {
        // Subscribe to changes in the shared passManager's passes array
        passManager.$passes.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
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
