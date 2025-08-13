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
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            if scannerViewModel.scannerStatus == .scannerAvailable {
                // Camera view goes to edges of screen
                PassScannerViewController(
                    recognizedCode: $scannerViewModel.recognizedCode,
                    recognizedDataType: .barcode(),
                    viewModel: scannerViewModel
                )
                .ignoresSafeArea()
                
                ScannerOverlayView(
                    message: scannerViewModel.isBarcodeDetected ? "Barcode detected!" : "Align barcode within the frame",
                    isBarcodeDetected: scannerViewModel.isBarcodeDetected,
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
        .navigationBarBackButtonHidden(false)
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
                },
                onCancel: onCancel
            )
        }
    }
    
    private var scannerUnavailableView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.appTextLight)
                
                Text("Scanner Unavailable")
                    .font(.appHeadline)
                    .foregroundColor(AppTheme.appTextPrimary)
                
                Text("Camera scanning is not available on this device. Please try again later or use a different device.")
                    .font(.appBody)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.appTextLight)
                    .padding(.horizontal, 32)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .font(.appButtonSecondary)
            .foregroundColor(AppTheme.appTextLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.appTextLight.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(AppTheme.appBackgroundBG))
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
            },
            onCancel: {
                print("Cancelled in preview")
            }
        )
    }
}
