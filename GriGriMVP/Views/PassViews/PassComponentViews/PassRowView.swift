//
//  PassRowView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import SwiftUI
import Foundation

// MARK: - Static Pass Content (Never Redraws)
struct StaticPassRowContent: View {
    let pass: Pass
    let gym: Gym?
    let company: GymCompany?
    let displayName: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Show company or gym image
            if let company = company {
                CachedCompanyImageView(company: company, size: 60)
            } else {
                CachedGymImageView(gym: gym, size: 60)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Pass title - use displayName (company or gym name)
                Text(displayName)
                    .font(.headline)
                    .foregroundColor(AppTheme.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Pass metadata - static content
                PassMetadataView(pass: pass)
            }
            .padding(.trailing, 80) // Reserve space for active indicator
        }
        .frame(minHeight: 80)
        .padding(.vertical, 4)
    }
}

// MARK: - Dynamic Active Indicator (Only Redraws When Active State Changes)
struct DynamicActiveIndicator: View {
    let pass: Pass
    
    var body: some View {
        HStack {
            Spacer()
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
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: pass.isActive)
    }
}

// MARK: - Complete Pass Row (Combines Static + Dynamic)
struct PassRowView: View {
    @ObservedObject var viewModel: PassDisplayViewModel
    let pass: Pass
    @State private var showingEnhancedView = false
    
    // Get gym and company data immediately at initialization
    private var gym: Gym? {
        viewModel.gym(for: pass)
    }
    
    private var company: GymCompany? {
        viewModel.company(for: pass)
    }
    
    private var displayName: String {
        viewModel.displayName(for: pass)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Static content (never redraws)
            StaticPassRowContent(
                pass: pass,
                gym: gym,
                company: company,
                displayName: displayName
            )
            
            // Dynamic active indicator overlay (only redraws when active state changes)
            DynamicActiveIndicator(pass: pass)
                .padding(.top, 8)
                .padding(.trailing, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !pass.isActive {
                viewModel.setActivePass(for: pass.id)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            // Add "View Pass" swipe action on the left
            Button {
                showingEnhancedView = true
            } label: {
                Label("View Pass", systemImage: "viewfinder")
                    .labelStyle(.titleAndIcon)
            }
            .tint(AppTheme.appPrimary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                viewModel.confirmDelete(for: pass)
            } label: {
                Label("Delete Pass", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .tint(Color.red)
        }
        .fullScreenCover(isPresented: $showingEnhancedView) {
            EnhancedPassView(pass: pass, displayViewModel: viewModel)
        }
    }
}



// Separate component for stable pass metadata
struct PassMetadataView: View {
    let pass: Pass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
}
