//
//  PassScannerViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI
import VisionKit
import AVKit
import Combine

enum PassScannerStatus {
    case notDetermined
    case noCameraAccess
    case cameraNotFound
    case scannerAvailable
    case scannerNotAvailable
}

@MainActor
final class PassScannerViewModel: ObservableObject {
    
    @Published var scannerStatus: PassScannerStatus = .notDetermined
    @Published var recognizedCode: RecognizedItem?
    @Published var isBarcodeDetected: Bool = false
    
    // Use a callback instead of relying on property observation
    var onBarcodeDetected: ((RecognizedItem) -> Void)?
    
    // Use a passed-in PassViewModel instead of creating a new one
    private let passViewModel: PassViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(scannerStatus: PassScannerStatus, recognizedCode: RecognizedItem?, passViewModel: PassViewModel) {
        self.scannerStatus = scannerStatus
        self.recognizedCode = recognizedCode
        self.passViewModel = passViewModel
        
        Task {
            try? await requestPassScannerStatus()
        }
        
        // Monitor recognizedCode changes through combine
        $recognizedCode
            .dropFirst()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] newItem in
                self?.isBarcodeDetected = true
                
                // Add a short delay before triggering navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Call the callback with the new item
                    self?.onBarcodeDetected?(newItem)
                }
            }
            .store(in: &cancellables)
        
        // Monitor changes to isBarcodeDetected separately
        $recognizedCode
            .map { $0 != nil }
            .assign(to: &$isBarcodeDetected)
    }
    
    var recognizedDataType: DataScannerViewController.RecognizedDataType {
        .barcode()
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func processScannedCode(_ item: RecognizedItem) {
        guard case .barcode(let barcode) = item else { return }
        
        passViewModel.handleScannedBarcode(
            code: barcode.payloadStringValue ?? "Unknown",
            codeType: barcode.observation.symbology.rawValue
        )
    }
    
    // Call this method when a potential barcode is detected but not yet confirmed
    func updateBarcodeDetectionStatus(_ detected: Bool) {
        DispatchQueue.main.async {
            self.isBarcodeDetected = detected
        }
    }
    
    func requestPassScannerStatus() async throws {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            scannerStatus = .cameraNotFound
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            scannerStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            
        case .restricted, .denied:
            scannerStatus = .noCameraAccess
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                scannerStatus = isScannerAvailable ? .scannerAvailable: .scannerNotAvailable
            }
            else { scannerStatus = .noCameraAccess
            }
        
        default: break
            
        }
    }
}
