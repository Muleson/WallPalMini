//
//  PassScannerView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import SwiftUI
import VisionKit
import Combine

struct PassScannerView: View {
    
    // Use the shared PassViewModel instance from parent view
    @ObservedObject var passViewModel: PassViewModel
    @StateObject private var scannerViewModel: PassScannerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var navigateToBarcodeDetail: Bool = false
    @State private var navigateToManualInput: Bool = false
    @State private var dismissToRoot: Bool = false
    
    var isPrimary: Bool
    
    // Callback for when a pass is added
    var onPassAdded: () -> Void
    
    init(passViewModel: PassViewModel, isPrimary: Bool, onPassAdded: @escaping () -> Void) {
        self.passViewModel = passViewModel
        self.isPrimary = isPrimary
        self.onPassAdded = onPassAdded
        
        // Use the same passViewModel for scanner
        _scannerViewModel = StateObject(
            wrappedValue: PassScannerViewModel(
                scannerStatus: .notDetermined,
                recognizedCode: nil,
                passViewModel: passViewModel
            )
        )
    }
    
    var body: some View {
        ZStack {
            switch scannerViewModel.scannerStatus {
            case .scannerAvailable:
                ZStack {
                    mainView
                    ScannerOverlayView(
                        message: scannerViewModel.isBarcodeDetected ? "Barcode detected!" : "Align barcode within frame",
                        isBarcodeDetected: scannerViewModel.isBarcodeDetected,
                        onManualInput: {
                            navigateToManualInput = true
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                }
            case .scannerNotAvailable:
                Text("Unfortunately your device does not support our scanner. ")
            case .cameraNotFound:
                Text("Your device doesn't appear to have a camera.")
            case .noCameraAccess:
                Text("Our scanner requires access to your camera.")
            case .notDetermined:
                Text("Requesting camera access ")
            }
        }
        .onAppear {
            // Show the gym name in the navigation title if available
           if let gym = passViewModel.selectedGym {
               // Update UI to show which gym's pass is being scanned
               print("Scanning pass for \(gym.name)")
           }
            // Set up a subscription to the barcodeDetected publisher
            scannerViewModel.onBarcodeDetected = { item in
                // Process the barcode and navigate
                processBarcode(item)
                navigateToBarcodeDetail = true
            }
        }
        .onChange(of: dismissToRoot) {_, newValue in
            if newValue {
                // Dismiss this sheet to return to root
                dismiss()
            }
        }
        .navigationDestination(isPresented: $navigateToBarcodeDetail) {
            PassConfirmationView(
                passViewModel: passViewModel,
                dismissToRoot: $dismissToRoot,
                isPrimary: isPrimary,
                onPassSaved: onPassAdded
            )
        }
        .navigationDestination(isPresented: $navigateToManualInput) {
            ManualInputView()
        }
        .navigationTitle("Scan Pass")
        .navigationBarBackButtonHidden(true) // Hide back button since we have our own cancel button
    }
    
    private func processBarcode(_ item: RecognizedItem) {
        guard case .barcode(let barcode) = item else { return }
        
        passViewModel.handleScannedBarcode(
            code: barcode.payloadStringValue ?? "Unknown",
            codeType: barcode.observation.symbology.rawValue
        )
    }
    
    private var mainView: some View {
        PassScannerViewController(
            recognizedCode: $scannerViewModel.recognizedCode,
            recognizedDataType: scannerViewModel.recognizedDataType,
            viewModel: scannerViewModel
        )
    }
}
