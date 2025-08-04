//
//  BarcodeImageView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 31/12/2024.
//

import Foundation
import SwiftUI

struct BarcodeImageView: View {
    let pass: Pass
    
    @ObservedObject var viewModel: PassDisplayViewModel
    
    var body: some View {
        if let barcodeImage = viewModel.generateBarcodeImage(from: pass) {
            Image(uiImage: barcodeImage)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(height: 150)
                .padding(.vertical, 8)
        }
    }
}
