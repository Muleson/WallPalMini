//
//  EnhancedPassView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/09/2025.
//

import SwiftUI

struct EnhancedPassView: View {
    let pass: Pass
    let displayViewModel: PassDisplayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    
    var body: some View {
        ZStack {
            // Full screen white background for maximum contrast
            Color.white
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top section with close button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                            .background(Circle().fill(Color.white))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Main content area - centered barcode and info
                VStack(spacing: 24) {
                    // Gym name
                    Text(pass.mainInformation.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Large barcode for scanning with enhanced frame
                    if let barcodeImage = displayViewModel.generateBarcodeImage(from: pass) {
                        let isLandscapeBarcode = barcodeImage.size.width > barcodeImage.size.height * 1.5
                        
                        if isLandscapeBarcode {
                            // Always show landscape barcodes in landscape orientation with more vertical space
                            GeometryReader { geometry in
                                Image(uiImage: barcodeImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(
                                        maxWidth: geometry.size.height - 60, // Use height as width in landscape
                                        maxHeight: geometry.size.width - 60   // Use width as height in landscape
                                    )
                                    .padding(.all, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    )
                                    .rotationEffect(.degrees(90)) // Always rotate landscape barcodes
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(height: 400) // Increased height for better barcode visibility
                            .padding(.horizontal, 20)
                            
                            // Note prompting user to rotate phone for scanning
                            HStack(spacing: 8) {
                                Image(systemName: "rotate.right")
                                Text("Rotate your phone when scanning")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.top, 16)
                        } else {
                            // Portrait orientation for square/QR codes
                            GeometryReader { geometry in
                                Image(uiImage: barcodeImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(
                                        maxWidth: geometry.size.width - 64,
                                        maxHeight: min(geometry.size.height * 0.6, 400)
                                    )
                                    .clipped()
                                    .padding(.all, 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(height: 450)
                            .padding(.horizontal, 32)
                        }
                    }
                    
                    // Pass type and date added
                    VStack(spacing: 8) {
                        Text(pass.passType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Added \(pass.mainInformation.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Bottom instruction text
                VStack(spacing: 8) {
                    Text("Present this code at the gym entrance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap anywhere to close")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
        }
        .onTapGesture {
            // Allow tap to close
            dismiss()
        }
        .onAppear {
            // Store original brightness and set to maximum
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            // Restore original brightness
            UIScreen.main.brightness = originalBrightness
        }
        .preferredColorScheme(.light) // Force light mode for better barcode contrast
        .statusBarHidden() // Hide status bar for full immersion
    }
}

#Preview {
    let samplePass = Pass(
        mainInformation: MainInformation(title: "Sample Gym", date: Date()),
        barcodeData: BarcodeData(code: "1234567890", codeType: "Code128"),
        passType: .membership,
        isActive: true,
        isFavourite: false
    )
    
    EnhancedPassView(
        pass: samplePass,
        displayViewModel: PassDisplayViewModel()
    )
}