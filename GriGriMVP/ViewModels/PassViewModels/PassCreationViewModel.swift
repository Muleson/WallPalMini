//
//  PassCreationViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 03/08/2025.
//

import Foundation
import UIKit
import Vision
import Combine
import SwiftUI

@MainActor
class PassCreationViewModel: ObservableObject {
    // MARK: - Gym Selection Properties
    @Published var gyms: [Gym] = []
    @Published var selectedGym: Gym?
    @Published var isLoading: Bool = false
    @Published var searchError: String? = nil
    @Published var gymDistances: [String: String] = [:]
    @Published var companies: [GymCompany] = []
    
    // MARK: - Pass Creation Properties
    @Published var titlePlaceholder: String = ""
    @Published var showTitlePrompt: Bool = false
    @Published var showScanner: Bool = false
    @Published var duplicatePassAlert: Bool = false
    @Published var duplicatePassName: String = ""
    @Published var lastSavedPassWasSuccessful: Bool = false
    @Published var selectedPassType: PassType = .membership
    @Published var hasSelectedPassType: Bool = false
    
    // MARK: - Gym Duplicate Properties
    @Published var showGymDuplicateConfirmation: Bool = false
    @Published var duplicateGymPassFound: Pass? = nil

    
    private let gymRepository: GymRepositoryProtocol
    private let gymCompanyRepository: GymCompanyRepositoryProtocol
    private let passManager = PassManager.shared // Use shared instead of creating new instance
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    var lastScannedPass: Pass?
    
    init(gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository(),
         gymCompanyRepository: GymCompanyRepositoryProtocol = RepositoryFactory.createGymCompanyRepository()) {
        self.gymRepository = gymRepository
        self.gymCompanyRepository = gymCompanyRepository
    }
    
    // MARK: - Gym Selection Logic
    
    func loadGyms() {
        isLoading = true
        searchError = nil
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Load gyms and companies in parallel
                async let loadedGyms = gymRepository.fetchAllGyms()
                async let loadedCompanies = gymCompanyRepository.fetchAllCompanies()
                
                let (gyms, companies) = try await (loadedGyms, loadedCompanies)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.gyms = gyms
                    self.companies = companies
                    self.isLoading = false
                }
                
                await calculateDistancesToGyms()
                
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.searchError = "Failed to load gyms: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Helper to get company name for a gym
    func companyName(for gym: Gym) -> String? {
        guard let companyId = gym.companyId else { return nil }
        return companies.first { $0.id == companyId }?.name
    }
    
    // Helper to get company for selected gym
    var selectedGymCompany: GymCompany? {
        guard let gym = selectedGym,
              let companyId = gym.companyId else {
            return nil
        }
        return companies.first { $0.id == companyId }
    }
    
    // Get list of gyms belonging to the selected gym's company
    var companyGyms: [Gym] {
        guard let company = selectedGymCompany,
              let gymIds = company.gymIds else {
            return []
        }
        return gyms.filter { gymIds.contains($0.id) }
    }
    
    // Check if selected gym is part of a chain
    var isChainGym: Bool {
        selectedGymCompany != nil
    }
    
    // Get the display name for the pass (company or gym name)
    var passDisplayName: String {
        if let company = selectedGymCompany {
            return company.name
        } else if let gym = selectedGym {
            return gym.name
        }
        return ""
    }
    
    // Get the profile image for display (company or gym)
    var passDisplayImage: MediaItem? {
        if let company = selectedGymCompany {
            return company.profileImage
        } else if let gym = selectedGym {
            return gym.profileImage
        }
        return nil
    }
    
    func searchGyms(query: String) {
        searchTask?.cancel()
        
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let filteredGyms = try await gymRepository.searchGyms(query: query)
                
                if !Task.isCancelled {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.gyms = filteredGyms
                    }
                    await calculateDistancesToGyms()
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.searchError = "Search failed: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        searchTask = task
    }
    
    private func calculateDistancesToGyms() async {
        do {
            let userLocation = try await LocationService.shared.requestCurrentLocation()
            var distances: [String: String] = [:]
            
            for gym in gyms {
                let distanceInMeters = await LocationService.shared.distance(from: userLocation, to: gym.location)
                
                if distanceInMeters < 1000 {
                    distances[gym.id] = String(format: "%.0f m", distanceInMeters)
                } else {
                    let distanceInKm = distanceInMeters / 1000
                    distances[gym.id] = String(format: "%.1f km", distanceInKm)
                }
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.gymDistances = distances
            }
        } catch LocationError.requestInProgress {
            print("Location request already in progress, skipping distance calculation")
        } catch {
            print("Location error: \(error.localizedDescription)")
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.gymDistances = [:]
            }
        }
    }
    
    // MARK: - Pass Creation Logic
    
    func prepareForScan(with gym: Gym) {
        selectedGym = gym
        titlePlaceholder = gym.name
        showScanner = true
    }
    
    func getExpectedBarcodeType() -> [VNBarcodeSymbology] {
        // Can be customized based on selected gym in the future
        return [.qr, .code128, .pdf417, .aztec]
    }
    
    func handleScannedBarcode(code: String, codeType: String) {
        let barcodeData = BarcodeData(code: code, codeType: codeType)
        let mainInfo = MainInformation(title: "", date: Date())
        
        lastScannedPass = Pass(mainInformation: mainInfo, barcodeData: barcodeData, passType: selectedPassType, gymId: selectedGym?.id)
        showTitlePrompt = true
        
        // Check for duplicates
        if let duplicatePass = findDuplicatePass(code: code, codeType: codeType) {
            duplicatePassName = duplicatePass.mainInformation.title
        } else {
            duplicatePassName = ""
        }
    }
    
    func saveScanResultWithGym(code: String, codeType: String, primaryStatus: Bool = false) -> Bool {
        guard let gym = selectedGym else { 
            lastSavedPassWasSuccessful = false
            return false 
        }
        
        // Check for barcode duplicates first
        if findDuplicatePass(code: code, codeType: codeType) != nil {
            duplicatePassAlert = true
            lastSavedPassWasSuccessful = false
            return false
        }
        
        // Check for gym duplicates (or company duplicates)
        if let company = selectedGymCompany {
            // Check if user already has a pass for this company
            if let duplicateCompanyPass = findDuplicateCompanyPass(companyId: company.id) {
                duplicateGymPassFound = duplicateCompanyPass
                showGymDuplicateConfirmation = true
                lastSavedPassWasSuccessful = false
                return false
            }
        } else {
            // Check for single gym duplicates
            if let duplicateGymPass = findDuplicateGymPass(gymId: gym.id) {
                duplicateGymPassFound = duplicateGymPass
                showGymDuplicateConfirmation = true
                lastSavedPassWasSuccessful = false
                return false
            }
        }
        
        let barcodeData = BarcodeData(code: code, codeType: codeType)
        
        // Create pass based on whether gym is part of a chain
        let pass: Pass
        if let company = selectedGymCompany {
            // Chain pass: assign to company
            let mainInfo = MainInformation(title: company.name, date: Date())
            pass = Pass(
                mainInformation: mainInfo,
                barcodeData: barcodeData,
                passType: selectedPassType,
                gymCompanyId: company.id,
                gymId: nil,
                isActive: primaryStatus
            )
        } else {
            // Independent gym: assign to specific gym
            let mainInfo = MainInformation(title: gym.name, date: Date())
            pass = Pass(
                mainInformation: mainInfo,
                barcodeData: barcodeData,
                passType: selectedPassType,
                gymCompanyId: nil,
                gymId: gym.id,
                isActive: primaryStatus
            )
        }
                
        let success = passManager.addPass(pass)
        
        if success {
            lastSavedPassWasSuccessful = true  // Set to true on successful save
            resetCreationState()
        } else {
            lastSavedPassWasSuccessful = false  // Set to false on failed save
            duplicatePassAlert = true
        }
        
        return success
    }
    
    func savePassWithGym(primaryStatus: Bool = false) -> Bool {
        guard var pass = lastScannedPass else { 
            lastSavedPassWasSuccessful = false
            return false 
        }
        
        // Determine the title and IDs for the pass based on gym/company
        if let gym = selectedGym {
            if let company = selectedGymCompany {
                // Chain pass
                pass.mainInformation = MainInformation(
                    title: company.name,
                    date: pass.mainInformation.date
                )
                pass.gymCompanyId = company.id
                pass.gymId = nil
            } else {
                // Independent gym pass
                pass.mainInformation = MainInformation(
                    title: gym.name,
                    date: pass.mainInformation.date
                )
                pass.gymId = gym.id
                pass.gymCompanyId = nil
            }
        } else if !titlePlaceholder.isEmpty {
            pass.mainInformation = MainInformation(
                title: titlePlaceholder,
                date: pass.mainInformation.date
            )
            // gymId and gymCompanyId remain as previously set or nil
        } else {
            lastSavedPassWasSuccessful = false
            return false
        }
        
        pass.isActive = primaryStatus
        
        // Update the pass type with the currently selected value
        pass.passType = selectedPassType
        
        // Check for barcode duplicates first
        if let duplicatePass = findDuplicatePass(code: pass.barcodeData.code, codeType: pass.barcodeData.codeType) {
            duplicatePassName = duplicatePass.mainInformation.title
            duplicatePassAlert = true
            lastSavedPassWasSuccessful = false
            return false
        }
        
        // Check for gym/company duplicates
        if let companyId = pass.gymCompanyId {
            if let duplicateCompanyPass = findDuplicateCompanyPass(companyId: companyId) {
                duplicateGymPassFound = duplicateCompanyPass
                showGymDuplicateConfirmation = true
                lastSavedPassWasSuccessful = false
                return false
            }
        } else if let gymId = pass.gymId {
            if let duplicateGymPass = findDuplicateGymPass(gymId: gymId) {
                duplicateGymPassFound = duplicateGymPass
                showGymDuplicateConfirmation = true
                lastSavedPassWasSuccessful = false
                return false
            }
        }
            
        let success = passManager.addPass(pass)
        
        if success {
            lastSavedPassWasSuccessful = true  // Set to true on successful save
            resetCreationState()
        } else {
            lastSavedPassWasSuccessful = false  // Set to false on failed save
            duplicatePassAlert = true
        }
        
        return success
    }
    
    private func findDuplicatePass(code: String, codeType: String) -> Pass? {
        return passManager.passes.first { pass in
            return pass.barcodeData.code == code && pass.barcodeData.codeType == codeType
        }
    }
    
    private func findDuplicateGymPass(gymId: String) -> Pass? {
        return passManager.passes.first { pass in
            return pass.gymId == gymId
        }
    }
    
    private func findDuplicateCompanyPass(companyId: String) -> Pass? {
        return passManager.passes.first { pass in
            return pass.gymCompanyId == companyId
        }
    }
    
    // Public method to check for duplicate gym passes (including company passes)
    func hasExistingPassForGym(gymId: String) -> Pass? {
        // First check if there's a direct gym pass
        if let directPass = findDuplicateGymPass(gymId: gymId) {
            return directPass
        }
        
        // Then check if gym belongs to a company with an existing pass
        if let gym = gyms.first(where: { $0.id == gymId }),
           let companyId = gym.companyId,
           let companyPass = findDuplicateCompanyPass(companyId: companyId) {
            return companyPass
        }
        
        return nil
    }
    
    // MARK: - Gym Duplicate Handling
    
    func replaceExistingGymPass(primaryStatus: Bool = false) -> Bool {
        guard var newPass = lastScannedPass,
              let duplicatePass = duplicateGymPassFound else {
            lastSavedPassWasSuccessful = false
            return false
        }
        
        // Prepare the new pass with proper title and IDs
        if let gym = selectedGym {
            if let company = selectedGymCompany {
                // Chain pass
                newPass.mainInformation = MainInformation(
                    title: company.name,
                    date: newPass.mainInformation.date
                )
                newPass.gymCompanyId = company.id
                newPass.gymId = nil
            } else {
                // Independent gym pass
                newPass.mainInformation = MainInformation(
                    title: gym.name,
                    date: newPass.mainInformation.date
                )
                newPass.gymId = gym.id
                newPass.gymCompanyId = nil
            }
        }
        
        newPass.isActive = primaryStatus
        newPass.passType = selectedPassType
        
        // Remove the old pass
        passManager.delete(id: duplicatePass.id, wasItemPrimary: duplicatePass.isActive)
        
        // Add the new pass
        let success = passManager.addPass(newPass)
        
        if success {
            lastSavedPassWasSuccessful = true
            resetCreationState()
        } else {
            lastSavedPassWasSuccessful = false
        }
        
        return success
    }
    
    func cancelGymDuplicateFlow() {
        showGymDuplicateConfirmation = false
        duplicateGymPassFound = nil
        lastSavedPassWasSuccessful = false
    }
    
    private func resetCreationState() {
        selectedGym = nil
        titlePlaceholder = ""
        lastScannedPass = nil
        showTitlePrompt = false
        showScanner = false
        duplicatePassName = ""
        lastSavedPassWasSuccessful = false  // Reset the success flag
        selectedPassType = .membership  // Reset to default
        hasSelectedPassType = false  // Reset selection flag
        showGymDuplicateConfirmation = false
        duplicateGymPassFound = nil
    }
}

