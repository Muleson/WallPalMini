//
//  PassRowView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import SwiftUI
import Foundation

struct PassRowView: View {
    
    @ObservedObject var viewModel: PassViewModel
    @Binding var passToDelete: Pass?
    let pass: Pass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pass.mainInformation.title)
                .font(.headline)
            
            Text("Scanned: \(pass.mainInformation.date.formatted())")
                .font(.subheadline)
                .frame(alignment: .trailing)
            
            if pass.isActive {
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .padding(.top, 4)
            }
        }
        .frame(minHeight: 80)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.setActivePass(for: pass.id)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.confirmDelete(for: pass)
            } label: {
                Label("Delete Pass", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .tint(Color.red)
            
            Button {
                viewModel.setActivePass(for: pass.id)
            } label: {
                Label("Make Primary", systemImage: "star")
                    .labelStyle(.titleAndIcon)
            }
            .tint(AppTheme.appAccent)
        }
    }
}
