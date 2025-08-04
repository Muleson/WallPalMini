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
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(pass.mainInformation.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Active tag
                    if pass.isActive {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.appPrimary)
                            .cornerRadius(8)
                    }
                }
                
                Text("Scanned: \(pass.mainInformation.date.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
