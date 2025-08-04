//
//  BarcodeGenerator.swift
//  GriGriMVP
//
//  Created by Sam Quested on 03/08/2025.
//

import UIKit
import CoreImage

struct PassBarcodeGenerator {
    
    static func generateImage(from pass: Pass) -> UIImage? {
        return generateBarcodeImage(
            code: pass.barcodeData.code,
            codeType: pass.barcodeData.codeType
        )
    }
    
    static func generateBarcodeImage(code: String, codeType: String) -> UIImage? {
        guard let data = code.data(using: .ascii) else {
            print("Failed to convert code to ASCII data")
            return nil
        }
        
        // Determine the Core Image filter based on barcode type
        let filterName = getFilterName(for: codeType)
        
        guard let filter = CIFilter(name: filterName) else {
            print("Failed to create filter for type: \(filterName)")
            return nil
        }
        
        // Set the input data
        filter.setValue(data, forKey: "inputMessage")
        
        // Configure specific parameters for different barcode types
        configureFilter(filter, for: filterName)
        
        guard let outputImage = filter.outputImage else {
            print("Filter failed to generate output image")
            return nil
        }
        
        // Scale the image for better quality and visibility
        let scaledImage = scaleImage(outputImage, for: filterName)
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Private Helper Methods
    
    private static func getFilterName(for codeType: String) -> String {
        let normalizedType = codeType.lowercased()
        
        switch normalizedType {
        case "org.iso.qrcode", "qr", "qrcode", "vnbarcodesymbologyqr":
            return "CIQRCodeGenerator"
        case "org.iso.code128", "code128", "vnbarcodesymbologycode128":
            return "CICode128BarcodeGenerator"
        case "org.iso.pdf417", "pdf417", "vnbarcodesymbologypdf417":
            return "CIPDF417BarcodeGenerator"
        case "org.iso.aztec", "aztec", "vnbarcodesymbologyaztec":
            return "CIAztecCodeGenerator"
        case "org.iso.code39", "code39", "vnbarcodesymbologycode39":
            return "CICode39BarcodeGenerator"
        case "org.iso.code93", "code93", "vnbarcodesymbologycode93":
            return "CICode93BarcodeGenerator"
        case "vnbarcodesymbologyi2of5", "i2of5", "interleaved2of5":
            return "CICode128BarcodeGenerator" // Note: Core Image doesn't have a dedicated I2of5 filter
        default:
            print("Unknown barcode type '\(codeType)', defaulting to QR Code")
            return "CIQRCodeGenerator"
        }
    }
    
    private static func configureFilter(_ filter: CIFilter, for filterName: String) {
        switch filterName {
        case "CIQRCodeGenerator":
            // Set error correction level for QR codes
            filter.setValue("M", forKey: "inputCorrectionLevel")
        case "CIPDF417BarcodeGenerator":
            // Configure PDF417 specific settings if needed
            filter.setValue(2, forKey: "inputMinWidth")
            filter.setValue(8, forKey: "inputMaxWidth")
            filter.setValue(3, forKey: "inputMinHeight")
            filter.setValue(90, forKey: "inputMaxHeight")
        default:
            // No special configuration needed for other types
            break
        }
    }
    
    private static func scaleImage(_ image: CIImage, for filterName: String) -> CIImage {
        let extent = image.extent
        
        // Different scaling for different barcode types
        let targetSize: CGSize
        
        switch filterName {
        case "CIQRCodeGenerator", "CIAztecCodeGenerator":
            // Square barcodes - make them reasonably sized
            targetSize = CGSize(width: 200, height: 200)
        case "CICode128BarcodeGenerator", "CICode39BarcodeGenerator", "CICode93BarcodeGenerator":
            // Linear barcodes - make them wide but not too tall
            targetSize = CGSize(width: 300, height: 100)
        case "CIPDF417BarcodeGenerator":
            // PDF417 - rectangular format
            targetSize = CGSize(width: 300, height: 150)
        default:
            // Default size
            targetSize = CGSize(width: 200, height: 200)
        }
        
        let scaleX = targetSize.width / extent.width
        let scaleY = targetSize.height / extent.height
        
        return image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
    
    // MARK: - Validation Methods
    
    static func isValidBarcodeType(_ codeType: String) -> Bool {
        let validTypes = [
            "org.iso.qrcode", "qr", "qrcode", "vnbarcodesymbologyqr",
            "org.iso.code128", "code128", "vnbarcodesymbologycode128",
            "org.iso.pdf417", "pdf417", "vnbarcodesymbologypdf417",
            "org.iso.aztec", "aztec", "vnbarcodesymbologyaztec",
            "org.iso.code39", "code39", "vnbarcodesymbologycode39",
            "org.iso.code93", "code93", "vnbarcodesymbologycode93",
            "vnbarcodesymbologyi2of5", "i2of5", "interleaved2of5"
        ]
        
        return validTypes.contains(codeType.lowercased())
    }
    
    static func getSupportedBarcodeTypes() -> [String] {
        return [
            "QR Code",
            "Code 128",
            "PDF417",
            "Aztec",
            "Code 39",
            "Code 93",
            "Interleaved 2 of 5"
        ]
    }
}

// MARK: - Extensions for Pass Integration

extension PassBarcodeGenerator {
    
    /// Generate a preview image for display in lists or cards
    static func generatePreviewImage(from pass: Pass, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        guard let baseImage = generateImage(from: pass) else { return nil }
        
        // Resize to preview size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Generate a high-quality image for scanning
    static func generateScanningImage(from pass: Pass) -> UIImage? {
        guard let data = pass.barcodeData.code.data(using: .ascii),
              let filter = CIFilter(name: getFilterName(for: pass.barcodeData.codeType)) else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        configureFilter(filter, for: getFilterName(for: pass.barcodeData.codeType))
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Higher resolution for scanning
        let scaleX = 400 / outputImage.extent.width
        let scaleY = 400 / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
