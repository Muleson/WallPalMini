//
//  PirmaryPassView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 31/12/2024.
//

import Foundation
import SwiftUI

struct PrimaryPassView: View {
    @StateObject private var primaryPassViewModel = PrimaryPassViewModel()
    @ObservedObject var displayViewModel: PassDisplayViewModel // Only for barcode generation
    @State private var showingEnhancedView = false
    
    var body: some View {
        if let primaryPass = primaryPassViewModel.primaryPass {
            VStack(alignment: .center, spacing: 16) {
                // Tappable barcode at the top with proper horizontal padding
                OptimizedBarcodeImageView(pass: primaryPass, displayViewModel: displayViewModel)
                    .padding(.horizontal, 20) // Add horizontal padding to prevent edge clipping
                    .onTapGesture {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        showingEnhancedView = true
                    }
                    .overlay(
                        // Subtle tap indicator that matches the barcode frame
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.appPrimary.opacity(0.3), lineWidth: 2)
                            .padding(.horizontal, 20) // Match the barcode padding
                    )
                
                // Gym title below the barcode
                VStack(spacing: 4) {
                    Text(primaryPass.mainInformation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.appTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap barcode to enlarge")
                        .font(.caption)
                        .foregroundColor(AppTheme.appTextLight)
                }
                .padding(.horizontal, 16)
            }
            .fullScreenCover(isPresented: $showingEnhancedView) {
                EnhancedPassView(pass: primaryPass, displayViewModel: displayViewModel)
            }
        }
    }
}

// Optimized barcode view that only updates when the pass itself changes
struct OptimizedBarcodeImageView: View {
    let pass: Pass
    let displayViewModel: PassDisplayViewModel
    
    var body: some View {
        if let barcodeImage = displayViewModel.generateBarcodeImage(from: pass) {
            GeometryReader { geometry in
                Image(uiImage: barcodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: geometry.size.width, maxHeight: 150)
                    .padding(.all, 24) // Increased padding for better whitespace
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .frame(height: 150 + 48) // Account for padding in total height
        }
    }
}
