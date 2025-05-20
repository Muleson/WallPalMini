//
//  PassManager.swift
//  GriGriMVP
//
//  Created by Sam Quested on 21/12/2024.
//

import Foundation

class PassManager: ObservableObject {
    @Published private(set) var passes: [Pass] = []
    private let userDefaults: UserDefaults
    private var passesKey = "saved_passes"
    
    init() {
        self.passes = []
        self.userDefaults = .standard
        self.passesKey = "saved_passes"
        loadPasses()
    }
    
    func addPass(_ pass: Pass) -> Bool {
        // Check for duplicates based on barcode data
        if isDuplicatePass(pass) {
            // DEBUG PRINT
            print("Duplicate pass detected - not adding")
            return false
        }
        
        // DEBUG PRINT
        print("Adding pass. Current passes count: \(passes.count)")

        var newPasses = passes
        var newPass = pass
        
        if passes.isEmpty {
            newPass = Pass(mainInformation: pass.mainInformation,
                           barcodeData: pass.barcodeData,
                           isActive: true)
        } else if newPass.isActive {
            
            // DEBUG PRINT
            print("New pass is primary, updating other passes")
            
            newPasses = passes.map { existingPass in
                Pass(mainInformation: existingPass.mainInformation,
                            barcodeData: existingPass.barcodeData,
                            isActive: false)
            }
        }
        newPasses.append(newPass)
        passes = newPasses
        
        // DEBUG PRINT
        print("After adding pass. Count: \(passes.count), Has primary: \(passes.contains(where: { $0.isActive }))")

        savePasses()
        return true
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
            var updatedPasss = pass
            if pass.id == id {
                updatedPasss = Pass(mainInformation: pass.mainInformation,
                                    barcodeData: pass.barcodeData,
                                    isActive: true)
            } else if pass.isActive {
                updatedPasss = Pass(mainInformation: pass.mainInformation,
                                    barcodeData: pass.barcodeData,
                                    isActive: false)
            }
            return updatedPasss
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
            //DEBUG
            print("No passes found in UserDefaults")
            return
        }

        do {
            passes = try JSONDecoder().decode([Pass].self, from: data)
            
            //DEBUG
            print("Loaded \(passes.count) passes from UserDefaults")
            print("Before ensurePrimaryPass - Has primary: \(passes.contains(where: { $0.isActive }))")
            
            ensureActivePass()
            
            //DEBUG
            print("After ensurePrimaryPass - Has primary: \(passes.contains(where: { $0.isActive }))")

        } catch {
            print("Failed to decode passes: \(error)")
            passes = []
        }
    }
}

extension PassManager: DeletionManager {
    typealias Item = Pass
    
    func delete(id: UUID, wasItemPrimary: Bool) {
        passes.removeAll(where: { $0.id == id })
        
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
