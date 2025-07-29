//
//  PassViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import Foundation
import CoreImage
import UIKit
import Vision
import Combine
import SwiftUI

class PassViewModel: ObservableObject {
    // Pass management properties
    @Published var passes: [Pass] = []
    @Published var primaryPass: Pass? = nil
    @Published var deletionState: DeletionState<Pass> = .none
    
    // Pass addition properties
    @Published var isLoading: Bool = false
    @Published var titlePlaceholder: String = ""
    @Published var showTitlePrompt: Bool = false
    @Published var showScenner: Bool = false
    @Published var searchError: String? = nil
    
    // Duplicate pass prevention properties
    @Published var duplicatePassAlert: Bool = false
    @Published var duplicatePassName: String = ""
    
    // Gym selection properties
    @Published var gyms: [Gym] = []
    @Published var selectedGym: Gym?
    
    private let gymRepository: GymRepositoryProtocol
    private let passManager: PassManager
    private var cancellables = Set<AnyCancellable>()
    var lastScannedPass: Pass?
    
    init(passManager: PassManager = PassManager(),
         gymRepository: GymRepositoryProtocol = RepositoryFactory.createGymRepository()) {
        self.passManager = passManager
        self.gymRepository = gymRepository
        
        loadPasses()
        loadGyms() // Load gyms on initialization
        
        // Subscribe to changes in the passManager
        passManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                self?.loadPasses()
            }
        }.store(in: &cancellables)
    }

    // Loads existing passes
    func loadPasses() {
        passes = passManager.passes
        primaryPass = passes.first(where: { $0.isActive })

    }
    
    // Loads available gyms to which a pass can be assigned
    func loadGyms() {
        isLoading = true
        searchError = nil
        
        Task {
            do {
                let loadedGyms = try await gymRepository.fetchAllGyms()
                
                await MainActor.run {
                    self.gyms = loadedGyms
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading gyms: \(error.localizedDescription)")
                    self.searchError = "Failed to load gyms"
                    self.isLoading = false
                    self.gyms = []
                }
            }
        }
    }
    
    // Triggers barcode scanning after a gym has been selected
    func prepareForScan(with gym: Gym) {
        selectedGym = gym
        titlePlaceholder = gym.name
        showScenner = true
    }
    
    // Gathers barcode type associated to the selected gym
    /// To be expanded
    func getExpectedBarCodeType() -> [VNBarcodeSymbology] {
        // Hardcode the scanner to look for a certain barcode type depending on barcode protocol of selected gym
        return [.qr, .code128, .pdf417, .aztec]
    }
    
    // Search through gyms for pass designation
    private var searchTask: Task<Void, Never>?
    
    @MainActor
    func searchGyms(query: String) {
        // Cancel previous task if any
        searchTask?.cancel()
        
        let task = Task {
            do {
                isLoading = true
                searchError = nil
                gyms = try await gymRepository.searchGyms(query: query)
                isLoading = false
            } catch {
                print("Error searching gyms: \(error)")
                searchError = "Search failed"
                isLoading = false
                gyms = []
            }
        }
        
        searchTask = task
    }
    
    // Transforms the scanned barcode into a re-presentable barcode
    func handleScannedBarcode(code: String, codeType: String) {
        let barcodeData = BarcodeData(code: code,
                                      codeType: codeType)
        let mainInfo = MainInformation(title: "",
                                       date: Date())
        
        lastScannedPass = Pass(mainInformation: mainInfo,
                               barcodeData: barcodeData)
        showTitlePrompt = true
        
        // Check if this is a duplicate
        if let duplicatePass = findDuplicatePass(code: code, codeType: codeType) {
            duplicatePassName = duplicatePass.mainInformation.title
        } else {
            duplicatePassName = ""
        }
        
    }
    
    // Saves scanned barcode with raw values to lastScannedPass
    func saveScanResultWithGym(code: String, codeType: String, primaryStatus: Bool = false) -> Bool {
        guard let gym = selectedGym else { return false }
        
        // Check for duplicates
        if findDuplicatePass(code: code, codeType: codeType) != nil {
            duplicatePassAlert = true
            return false
        }
        
        let barcodeData = BarcodeData(code: code, codeType: codeType)
        let mainInfo = MainInformation(title: gym.name, date: Date())
        
        let pass = Pass(mainInformation: mainInfo,
                        barcodeData: barcodeData,
                        isActive: primaryStatus)
                
        let success = passManager.addPass(pass)
        
        if success {
            loadPasses()
            // Reset state
            selectedGym = nil
            titlePlaceholder = ""
        } else {
            duplicatePassAlert = true
        }
        
        return success
    }
    
    // Save lastScannedPass to passes with gym information and primary status
    func savePassWithGym(primaryStatus: Bool = false) -> Bool {
        guard var pass = lastScannedPass else {
            return false
        }
        
        // Determine the title for the pass
        if let gym = selectedGym {
            // Create a new MainInformation object with updated title
            pass.mainInformation = MainInformation(
                title: gym.name,
                date: pass.mainInformation.date
            )
        } else if !titlePlaceholder.isEmpty {
            // Create a new MainInformation object with updated title
            pass.mainInformation = MainInformation(
                title: titlePlaceholder,
                date: pass.mainInformation.date
            )
        } else {
            return false
        }
        
        // Set primary status
        pass.isActive = primaryStatus
        
        // Check for duplicates one more time
        if let duplicatePass = findDuplicatePass(code: pass.barcodeData.code, codeType: pass.barcodeData.codeType) {
            duplicatePassName = duplicatePass.mainInformation.title
            duplicatePassAlert = true
            return false
        }
                
        let success = passManager.addPass(pass)
        
        if success {
            loadPasses()
            // Reset state after successful save
            selectedGym = nil
            titlePlaceholder = ""
            lastScannedPass = nil
        } else {
            duplicatePassAlert = true
        }
        
        return success
    }
    
    // Helper method to find duplicate passes
    func findDuplicatePass(code: String, codeType: String) -> Pass? {
        return passes.first { pass in
            return pass.barcodeData.code == code && pass.barcodeData.codeType == codeType
        }
    }
    
    func setFavouritePass(for passID: UUID) {
        
    }
    
    // Sets pass as active from list of scanned passes
    func setActivePass(for passID: UUID) {
        passManager.setActivePass(id: passID)
        
        // Force a refresh of the view model state
        objectWillChange.send()
        loadPasses()
    }
    
    // Confirmation step once deletePass has been triggered
    func confirmDelete(for pass: Pass) {
        deletionState = .confirming(pass)
    }
    
    // Cancels initiation of deletePass
    func cancelDelete() {
        deletionState = .none
    }
    
    // Deletes pass once confirmDelete has been called
    func handleDelete(for pass: Pass) {
        if case let .confirming(pass) = deletionState {
            passManager.delete(id: pass.id, wasItemPrimary: pass.isActive)
            loadPasses()
            deletionState = .none
        }
    }
    
    // Change pass title
    /// May not be necessary after passes tied to gym selection
    func updatePassTitle(for passID: UUID, with title: String) {
        passManager.updatePassTitle(for: passID, with: title)
        loadPasses()
    }
    
    
    private func getCIFilter(for barcodeType: String) -> CIFilter? {
        // Map VNBarcodeSymbology raw values to appropriate CIFilter
         switch barcodeType {
         case VNBarcodeSymbology.qr.rawValue:
             return CIFilter.qrCodeGenerator()
         case VNBarcodeSymbology.code128.rawValue:
             return CIFilter.code128BarcodeGenerator()
         case VNBarcodeSymbology.pdf417.rawValue:
             return CIFilter.pdf417BarcodeGenerator()
         case VNBarcodeSymbology.aztec.rawValue:
             return CIFilter.aztecCodeGenerator()
        // Unsuported barcode types default to code128 generator
         case VNBarcodeSymbology.code39.rawValue,
              VNBarcodeSymbology.ean13.rawValue,
              VNBarcodeSymbology.ean8.rawValue,
              VNBarcodeSymbology.upce.rawValue,
              VNBarcodeSymbology.itf14.rawValue,
             VNBarcodeSymbology.dataMatrix.rawValue:
             return CIFilter.code128BarcodeGenerator()
         default:
        // Default to QR code if type is not supported
             print("Unsupported barcode type: \(barcodeType), defaulting to QR")
             return CIFilter.qrCodeGenerator()
         }
     }
     
     private func configureFilter(_ filter: CIFilter, withData data: Data) {
         switch filter.name {
         case "CIQRCodeGenerator",
              "CIAztecCodeGenerator",
              "CIPDF417BarcodeGenerator",
              "CIDataMatrixGenerator":
             filter.setValue(data, forKey: "inputMessage")
             
         case "CICode128BarcodeGenerator",
              "CICode39BarcodeGenerator":
             filter.setValue(data, forKey: "inputMessage")
             filter.setValue(0.0, forKey: "inputQuietSpace")
             
         case "CIEAN13BarcodeGenerator",
              "CIEAN8BarcodeGenerator",
              "CIUPCEGenerator",
              "CIITF14BarcodeGenerator":
             if let stringValue = String(data: data, encoding: .ascii),
                let doubleValue = Double(stringValue) {
                 filter.setValue(doubleValue, forKey: "inputMessage")
             }
             
         default:
             filter.setValue(data, forKey: "inputMessage")
         }
     }
     
     func generateBarcodeImage(from pass: Pass) -> UIImage? {
         
         guard let filter = getCIFilter(for: pass.barcodeData.codeType) else {
             return nil
         }

         // Convert string to data
         guard let barcodeData = pass.barcodeData.code.data(using: .ascii) else {
             return nil
         }
         
         // Configure the filter based on its type
         configureFilter(filter, withData: barcodeData)
         
         // Get the output image
         guard let outputImage = filter.outputImage else {
             return nil
         }

         
         // Scale the image
         let transform = CGAffineTransform(scaleX: 10, y: 10)
         let scaledImage = outputImage.transformed(by: transform)
         
         // Create context and generate UIImage
         let context = CIContext()
         guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
             return nil
         }
         
         // For 1D barcodes, we want to adjust the aspect ratio
         let is1DBarcode = [
             VNBarcodeSymbology.code128.rawValue,
             VNBarcodeSymbology.code39.rawValue,
             VNBarcodeSymbology.ean13.rawValue,
             VNBarcodeSymbology.ean8.rawValue,
             VNBarcodeSymbology.upce.rawValue,
             VNBarcodeSymbology.itf14.rawValue
         ].contains(pass.barcodeData.codeType)
         
         if is1DBarcode {
             // For 1D barcodes, we create a resized image with appropriate aspect ratio
             let size = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height) * 0.5)
             UIGraphicsBeginImageContextWithOptions(size, false, 0)
             UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
             let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
             UIGraphicsEndImageContext()
             return resizedImage
         }
        return UIImage(cgImage: cgImage)
    }
}
