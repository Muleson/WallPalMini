//
//  PassScannerCamera.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI
import VisionKit
 
struct PassScannerViewController: UIViewControllerRepresentable {
    
    @Binding var recognizedCode: RecognizedItem?
    let recognizedDataType: DataScannerViewController.RecognizedDataType
    let recognizesMultipleItems: Bool = false
    let viewModel: PassScannerViewModel
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: false, // Disable default guidance since we have our own overlay
            isHighlightingEnabled: true
        )
        
        // Set region of interest for better scanning
        DispatchQueue.main.async {
            let screenBounds = UIScreen.main.bounds
            let scanWidth = min(screenBounds.width * 0.8, 300)
            let scanHeight = scanWidth * 0.6
            let centerX = screenBounds.width / 2
            let centerY = screenBounds.height / 2
            
            // Create region of interest rectangle
            let roiRect = CGRect(
                x: centerX - scanWidth / 2,
                y: centerY - scanHeight / 2,
                width: scanWidth,
                height: scanHeight
            )
            
            viewController.regionOfInterest = roiRect
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedCode: $recognizedCode, viewModel: viewModel)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedCode: RecognizedItem?
        let viewModel: PassScannerViewModel
        private var hasDetectedBarcode = false
        
        init(recognizedCode: Binding<RecognizedItem?>, viewModel: PassScannerViewModel) {
            self._recognizedCode = recognizedCode
            self.viewModel = viewModel
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard !hasDetectedBarcode else { return }
            processDetectedItem(item, dataScanner: dataScanner)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasDetectedBarcode else { return }
            
            if let firstBarcode = addedItems.first {
                processDetectedItem(firstBarcode, dataScanner: dataScanner)
            }
        }
        
        private func processDetectedItem(_ item: RecognizedItem, dataScanner: DataScannerViewController) {
            hasDetectedBarcode = true
            dataScanner.stopScanning()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Set the recognized code
                self.recognizedCode = item
                
                // Process the code in the view model using the correct method name
                self.viewModel.handleBarcodeDetection(item)
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Don't reset anything here to prevent oscillation
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            // Handle scanner unavailable error if needed
        }
    }
}
