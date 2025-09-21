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
            VStack(alignment: .center, spacing: 12) {
                // Gym info with profile image and title
                HStack(spacing: 12) {
                    // Gym profile image
                    /* if let gym = viewModel.gym(for: primaryPass), let profileImage = gym.profileImage {
                        AsyncImage(url: profileImage.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.appPrimary.opacity(0.15))
                                .overlay(
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.appPrimary)
                                )
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    } else {
                        // Fallback placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.appPrimary.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.appPrimary)
                            )
                    } */
                    
                    Text(primaryPass.mainInformation.title)
                        .font(.headline)
                }
                
                BarcodeImageView(pass: primaryPass, viewModel: viewModel)
            }
        }
    }
}
