//
//  PrimaryButtons.swift
//  GriGriMVP
//
//  Created by Sam Quested on 13/08/2025.
//

import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case outline
        case engaged // New style for active/favorited states
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return AppTheme.appPrimary
            case .outline:
                return .white
            case .engaged:
                return AppTheme.appPrimary.opacity(0.1)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .outline:
                return AppTheme.appPrimary
            case .engaged:
                return AppTheme.appPrimary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary:
                return Color.clear
            case .outline:
                return AppTheme.appPrimary
            case .engaged:
                return AppTheme.appPrimary // Solid primary color border
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .primary:
                return 0
            case .outline:
                return 3
            case .engaged:
                return 3
            }
        }
        
        var shadowColor: Color {
            switch self {
            case .primary:
                return AppTheme.appPrimary.opacity(0.3)
            case .outline:
                return AppTheme.appPrimary.opacity(0.3)
            case .engaged:
                return AppTheme.appPrimary.opacity(0.3)
            }
        }
    }
    
    enum ButtonSize {
        case compact    // For inline actions within content
        case standard   // Default size for most use cases
        case prominent  // For primary CTAs and navigation
        
        var font: Font {
            switch self {
            case .compact:
                return .system(size: 13, weight: .medium, design: .rounded)
            case .standard:
                return .system(size: 15, weight: .medium, design: .rounded)
            case .prominent:
                return .system(size: 18, weight: .semibold, design: .rounded)
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .compact:
                return 6
            case .standard:
                return 8
            case .prominent:
                return 12
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .compact:
                return 8
            case .standard:
                return 16
            case .prominent:
                return 24
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact:
                return 8
            case .standard:
                return 11
            case .prominent:
                return 14
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .compact:
                return 2
            case .standard:
                return 3
            case .prominent:
                return 4
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.font)
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, size.verticalPadding)
                .padding(.horizontal, size.horizontalPadding)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                .shadow(color: style.shadowColor, radius: size.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Convenience initializers
extension PrimaryActionButton {
    // Standard size convenience methods (maintains backward compatibility)
    static func primary(_ title: String, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: .primary, size: .standard, action: action)
    }
    
    static func outline(_ title: String, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: .outline, size: .standard, action: action)
    }
    
    static func engaged(_ title: String, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: .engaged, size: .standard, action: action)
    }
    
    static func toggle(_ title: String, isEngaged: Bool, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: isEngaged ? .engaged : .outline, size: .standard, action: action)
    }
    
    // Size-specific convenience methods
    static func primaryProminent(_ title: String, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: .primary, size: .prominent, action: action)
    }
    
    static func outlineCompact(_ title: String, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: .outline, size: .compact, action: action)
    }
    
    static func engagedCompact(_ title: String, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: .engaged, size: .compact, action: action)
    }
    
    // Custom size and style method for full control
    static func custom(_ title: String, style: ButtonStyle, size: ButtonSize, action: @escaping () -> Void) -> PrimaryActionButton {
        PrimaryActionButton(title: title, style: style, size: size, action: action)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Compact buttons for inline actions
        HStack(spacing: 8) {
            PrimaryActionButton.outlineCompact("View") {
                print("Compact view button tapped")
            }
            
            PrimaryActionButton.engagedCompact("Favorited") {
                print("Compact favorited button tapped")
            }
        }
        
        // Standard buttons (existing behavior)
        PrimaryActionButton.outline("Favourite") {
            print("Standard outline button tapped")
        }
        
        PrimaryActionButton.engaged("Favourited") {
            print("Standard engaged button tapped")
        }
        
        // Prominent buttons for main CTAs
        PrimaryActionButton.primaryProminent("Continue") {
            print("Prominent primary button tapped")
        }
        
        // Custom combination example
        PrimaryActionButton.custom("Custom Button", style: .primary, size: .compact) {
            print("Custom button tapped")
        }
    }
    .padding()
}
