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
    @ObservedObject var creationViewModel: PassCreationViewModel
    @StateObject private var scannerViewModel = PassScannerViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var navigateToConfirmation = false
    @State private var dismissToRoot = false
    
    let onPassAdded: () -> Void
    
    var body: some View {
        ZStack {
            if scannerViewModel.scannerStatus == .scannerAvailable {
                PassScannerViewController(
                    recognizedCode: $scannerViewModel.recognizedCode,
                    recognizedDataType: .barcode(),
                    viewModel: scannerViewModel
                )
                .ignoresSafeArea()
                
                ScannerOverlayView(
                    message: scannerViewModel.isBarcodeDetected ? "Barcode detected!" : "Align barcode within the frame",
                    isBarcodeDetected: scannerViewModel.isBarcodeDetected,
                    onManualInput: {
                        // Navigate to manual input
                    },
                    onCancel: {
                        dismiss()
                    }
                )
            } else {
                scannerUnavailableView
            }
        }
        .navigationTitle("Scan Pass")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            setupScannerCallbacks()
            Task {
                await scannerViewModel.requestCameraPermission()
            }
        }
        .navigationDestination(isPresented: $navigateToConfirmation) {
            PassConfirmationView(
                viewModel: creationViewModel,
                isPrimary: false,
                onPassSaved: {
                    onPassAdded()
                    dismissToRoot = true
                }
            )
        }
    }
    
    private var scannerUnavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Scanner Unavailable")
                .font(.headline)
            
            Text("Camera scanning is not available on this device")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Manual Input") {
                // Navigate to manual input
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func setupScannerCallbacks() {
        scannerViewModel.onBarcodeDetected = { code, codeType in
            // Pass the detected barcode to the creation view model
            creationViewModel.handleScannedBarcode(code: code, codeType: codeType)
            
            // Small delay to show detection feedback, then navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                navigateToConfirmation = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PassScannerView(
            creationViewModel: PassCreationViewModel(),
            onPassAdded: {
                print("Pass added in preview")
            }
        )
    }
}
