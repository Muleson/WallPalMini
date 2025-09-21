//
//  ViewMoreButton.swift
//  GriGriMVP
//
//  Created by Sam Quested on 02/09/2025.
//

import SwiftUI

struct ViewMoreButton: View {
    let width: CGFloat
    let height: CGFloat?
    let title: String
    let action: () -> Void
    
    init(width: CGFloat = 120, height: CGFloat? = nil, title: String = "View More", action: @escaping () -> Void) {
        self.width = width
        self.height = height
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Spacer()
                
                Circle()
                    .fill(AppTheme.appPrimary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(AppTheme.Spacing.cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width, height: height)
        .background(AppTheme.appContentBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .appCardShadow()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Compact event card size
        ViewMoreButton(width: 180, height: 170) {
            print("Compact View More tapped")
        }
        
        // Social event card size
        ViewMoreButton(width: 280, height: 150) {
            print("Social View More tapped")
        }
        
        HStack {
            ViewMoreButton(width: 120, height: 170) {
                print("Default View More tapped")
            }
            Spacer()
        }
        .padding()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
