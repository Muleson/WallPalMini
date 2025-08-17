//
//  PassRowView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import SwiftUI
import Foundation

struct PassRowView: View {
    @ObservedObject var viewModel: PassDisplayViewModel
    @Binding var passToDelete: Pass?
    let pass: Pass
    
    var body: some View {
        HStack(spacing: 12) {
            // Gym profile image with circular clip shape
            if let gym = viewModel.gym(for: pass), let profileImage = gym.profileImage {
                AsyncImage(url: profileImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.appPrimary.opacity(0.15))
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppTheme.appPrimary)
                        )
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.appPrimary.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppTheme.appPrimary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(pass.mainInformation.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.appTextPrimary)
                    
                    Spacer()
                    
                    // Active tag
                    if pass.isActive {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Active")
                        }
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.appPrimary)
                        .cornerRadius(12)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Added \(pass.mainInformation.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Pass type indicator
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(pass.passType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
        }
        .frame(minHeight: 80)
        .contentShape(Rectangle())
        .onTapGesture {
            // Only allow making pass active if it's not already active
            if !pass.isActive {
                viewModel.setActivePass(for: pass.id)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.confirmDelete(for: pass)
            } label: {
                Label("Delete Pass", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .tint(Color.red)
            
            // Only show "Make Primary" button if it's not already active
            if !pass.isActive {
                Button {
                    viewModel.setActivePass(for: pass.id)
                } label: {
                    Label("Make Primary", systemImage: "star")
                        .labelStyle(.titleAndIcon)
                }
                .tint(AppTheme.appPrimary)
            }
        }
    }
}
