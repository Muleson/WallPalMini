//
//  PassManager.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/12/2024.
//

import Foundation

class PassManager: ObservableObject {
    static let shared = PassManager()
    
    @Published private(set) var passes: [Pass] = []
    @Published var primaryPass: Pass? = nil
    @Published var nonPrimaryPasses: [Pass] = []
    
    private let userDefaults: UserDefaults
    private var passesKey = "saved_passes"
    
    private init() { // Make init private for singleton
        self.passes = []
        self.userDefaults = .standard
        self.passesKey = "saved_passes"
        loadPasses()
    }
    
    func addPass(_ pass: Pass) -> Bool {
        // Check for duplicates based on barcode data
        if isDuplicatePass(pass) {
            print("Duplicate pass detected - not adding")
            return false
        }
        
        print("Adding pass. Current passes count: \(passes.count)")

        var newPasses = passes
        var newPass = pass
        
        if passes.isEmpty {
            newPass = Pass(mainInformation: pass.mainInformation,
                           barcodeData: pass.barcodeData,
                           isActive: true)
        } else if newPass.isActive {
            print("New pass is primary, updating other passes")
            
            newPasses = passes.map { existingPass in
                Pass(mainInformation: existingPass.mainInformation,
                            barcodeData: existingPass.barcodeData,
                            isActive: false)
            }
        }
        newPasses.append(newPass)
        passes = newPasses
        
        // Update computed properties
        updateComputedProperties()
        
        print("After adding pass. Count: \(passes.count), Has primary: \(passes.contains(where: { $0.isActive }))")

        savePasses()
        return true
    }
    
    // Add this method to update computed properties
    private func updateComputedProperties() {
        primaryPass = passes.first(where: { $0.isActive })
        nonPrimaryPasses = passes.filter { !$0.isActive }
    }
    
    // Method to check if a pass is a duplicate
    private func isDuplicatePass(_ pass: Pass) -> Bool {
        // Check if we already have a pass with the same barcode data
        return passes.contains { existingPass in
            return existingPass.barcodeData.code == pass.barcodeData.code &&
                   existingPass.barcodeData.codeType == pass.barcodeData.codeType
        }
    }
    
    func updatePassTitle(for passId: UUID, with title: String) {
            if let index = passes.firstIndex(where: { $0.id == passId }) {
                let updatedInfo = MainInformation(
                    title: title,
                    date: passes[index].mainInformation.date
                )
                let updatedPass = Pass(
                    mainInformation: updatedInfo,
                    barcodeData: passes[index].barcodeData,
                    isActive: passes[index].isActive
                )
                passes[index] = updatedPass
                savePasses()
            }
        }
    
    func setFavouritePass(id: UUID) {
        let newPasses = passes.map { pass in
            var updatedPass = pass
            if pass.id == id {
                updatedPass = Pass(mainInformation: pass.mainInformation,
                                   barcodeData: pass.barcodeData,
                                   isActive: pass.isActive,
                                   isFavourite: true)
            } else if pass.isFavourite {
                updatedPass = Pass(mainInformation: pass.mainInformation,
                                   barcodeData: pass.barcodeData,
                                   isActive: pass.isActive,
                                   isFavourite: false)
            }
            return updatedPass
        }
        passes = newPasses
    }
    
    func setActivePass(id: UUID) {
        let newPasses = passes.map { pass in
            var updatedPass = pass
            if pass.id == id {
                updatedPass = Pass(mainInformation: pass.mainInformation,
                                    barcodeData: pass.barcodeData,
                                    isActive: true)
            } else if pass.isActive {
                updatedPass = Pass(mainInformation: pass.mainInformation,
                                    barcodeData: pass.barcodeData,
                                    isActive: false)
            }
            return updatedPass
        }
        passes = newPasses
        savePasses()
    }
    
    private func ensureActivePass() {
        if !passes.isEmpty && !passes.contains(where: { $0.isActive }) {
            var newPasses = passes
            newPasses[0] = Pass(mainInformation: passes[0].mainInformation,
                                barcodeData: passes[0].barcodeData,
                                isActive: true)
            passes = newPasses
            savePasses()
        }
    }
    
    private func savePasses() {
        if let encoded = try? JSONEncoder().encode(passes) {
            userDefaults.set(encoded, forKey: passesKey)
        }
    }
    
    private func loadPasses() {
        guard let data = userDefaults.data(forKey: passesKey) else {
            print("No passes found in UserDefaults")
            updateComputedProperties()
            return
        }

        do {
            passes = try JSONDecoder().decode([Pass].self, from: data)
            
            print("Loaded \(passes.count) passes from UserDefaults")
            print("Before ensurePrimaryPass - Has primary: \(passes.contains(where: { $0.isActive }))")
            
            ensureActivePass()
            updateComputedProperties()
            
            print("After ensurePrimaryPass - Has primary: \(passes.contains(where: { $0.isActive }))")

        } catch {
            print("Failed to decode passes: \(error)")
            passes = []
            updateComputedProperties()
        }
    }
}

extension PassManager: DeletionManager {
    typealias Item = Pass
    
    func delete(id: UUID, wasItemPrimary: Bool) {
        passes.removeAll(where: { $0.id == id })
        
        // If we deleted the primary pass and there are other passes, make the first one primary
        if wasItemPrimary && !passes.isEmpty {
            var newPasses = passes
            newPasses[0] = Pass(mainInformation: passes[0].mainInformation,
                                barcodeData: passes[0].barcodeData,
                                isActive: true)
            passes = newPasses
        }
        savePasses()
    }
}
