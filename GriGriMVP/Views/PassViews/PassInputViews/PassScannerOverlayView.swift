//
//  ScannerOverlayView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 29/03/2025.
//

import SwiftUI

struct ScannerOverlayView: View {
    let message: String
    let isBarcodeDetected: Bool
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background covering entire screen
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                // Scanning frame with cutout
                Path { path in
                    // Create full screen rectangle
                    let rect = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                    path.addRect(rect)
                    
                    // Calculate center scan area
                    let scanWidth = min(geometry.size.width * 0.75, 280)
                    let scanHeight = scanWidth * 0.5 // Better aspect ratio for barcodes
                    let scanRect = CGRect(
                        x: (geometry.size.width - scanWidth) / 2,
                        y: (geometry.size.height - scanHeight) / 2,
                        width: scanWidth,
                        height: scanHeight
                    )
                    
                    // Cut out scanning area
                    path.addRoundedRect(in: scanRect, cornerSize: CGSize(width: 12, height: 12))
                }
                .fill(
                    Color.black.opacity(0.6),
                    style: FillStyle(
                        eoFill: true,
                        antialiased: true
                    )
                )
                
                // Scanning area border
                let scanWidth = min(geometry.size.width * 0.75, 280)
                let scanHeight = scanWidth * 0.5
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isBarcodeDetected ? AppTheme.appPrimary : Color.white, 
                        lineWidth: isBarcodeDetected ? 4 : 2
                    )
                    .frame(width: scanWidth, height: scanHeight)
                    .position(x: centerX, y: centerY)
                    .animation(.easeInOut(duration: 0.3), value: isBarcodeDetected)
                
                // Corner indicators for better UX
                if !isBarcodeDetected {
                    ForEach(0..<4, id: \.self) { corner in
                        cornerIndicator(
                            corner: corner,
                            scanWidth: scanWidth,
                            scanHeight: scanHeight,
                            centerX: centerX,
                            centerY: centerY
                        )
                    }
                }
                
                // Guidance message
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: isBarcodeDetected ? "checkmark.circle.fill" : "viewfinder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isBarcodeDetected ? AppTheme.appPrimary : .white)
                        
                        Text(message)
                            .font(.appUnderline)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.7))
                )
                .position(x: centerX, y: centerY + scanHeight/2 + 40)
                
                // Cancel Button - positioned at bottom
                VStack {
                    Spacer()
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.appButtonSecondary)
                            .foregroundColor(AppTheme.appTextLight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.appTextLight.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // Helper function for corner indicators
    private func cornerIndicator(corner: Int, scanWidth: CGFloat, scanHeight: CGFloat, centerX: CGFloat, centerY: CGFloat) -> some View {
        let cornerSize: CGFloat = 20
        let thickness: CGFloat = 3
        
        let xOffset = scanWidth / 2 - cornerSize / 2
        let yOffset = scanHeight / 2 - cornerSize / 2
        
        let positions: [(CGFloat, CGFloat)] = [
            (-xOffset, -yOffset), // Top-left
            (xOffset, -yOffset),  // Top-right
            (-xOffset, yOffset),  // Bottom-left
            (xOffset, yOffset)    // Bottom-right
        ]
        
        let (x, y) = positions[corner]
        
        return ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.white)
                .frame(width: cornerSize, height: thickness)
            
            // Vertical line
            Rectangle()
                .fill(Color.white)
                .frame(width: thickness, height: cornerSize)
        }
        .position(x: centerX + x, y: centerY + y)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Normal state
        ScannerOverlayView(
            message: "Align barcode within the frame",
            isBarcodeDetected: false,
            onCancel: {}
        )
        .frame(height: 300)
        .background(Color.gray.opacity(0.3))
        
        // Detected state
        ScannerOverlayView(
            message: "Barcode detected!",
            isBarcodeDetected: true,
            onCancel: {}
        )
        .frame(height: 300)
        .background(Color.gray.opacity(0.3))
    }
    .padding()
    .background(Color(AppTheme.appBackgroundBG))
}
