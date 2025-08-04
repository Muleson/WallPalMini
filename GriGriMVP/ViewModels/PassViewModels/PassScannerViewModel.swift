//
//  PassScannerViewModel.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI
import VisionKit
import Vision
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
    
    // Prevent oscillation
    private var hasProcessedBarcode: Bool = false
    
    // Callback for when barcode is detected
    var onBarcodeDetected: ((String, String) -> Void)?
    
    init() {
        checkScannerAvailability()
    }
    
    func checkScannerAvailability() {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            scannerStatus = .scannerAvailable
        } else {
            scannerStatus = .scannerNotAvailable
        }
    }
    
    func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await MainActor.run { scannerStatus = .scannerAvailable }
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                scannerStatus = granted ? .scannerAvailable : .noCameraAccess
            }
        case .denied, .restricted:
            await MainActor.run { scannerStatus = .noCameraAccess }
        @unknown default:
            await MainActor.run { scannerStatus = .noCameraAccess }
        }
    }
    
    func handleBarcodeDetection(_ item: RecognizedItem) {
        guard !hasProcessedBarcode else { return }
        
        if case let .barcode(barcode) = item {
            hasProcessedBarcode = true
            isBarcodeDetected = true
            recognizedCode = item
            
            let code = barcode.payloadStringValue ?? ""
            
            // Direct access to symbology since observation is VNBarcodeObservation
            let codeType = barcode.observation.symbology.rawValue
            
            onBarcodeDetected?(code, codeType)
        }
    }
    
    func resetScanner() {
        hasProcessedBarcode = false
        isBarcodeDetected = false
        recognizedCode = nil
    }
}
