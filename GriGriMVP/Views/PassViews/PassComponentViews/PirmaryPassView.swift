//
//  PirmaryPassView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 31/12/2024.
//

import Foundation
import SwiftUI

struct PrimaryPassView: View {
    
    @ObservedObject var viewModel: PassDisplayViewModel
    
    var body: some View {
        if let primaryPass = viewModel.primaryPass {
            VStack(alignment: .center, spacing: 8) {
                Text(primaryPass.mainInformation.title)
                    .font(.headline)
                BarcodeImageView(pass: primaryPass, viewModel: viewModel)
            }
        }
    }
}
