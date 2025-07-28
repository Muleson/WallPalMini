//
//  NearbyPassCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//

import SwiftUI

struct NearbyGymCard: View {
    let gym: Gym?
    let distance: String?
    let onViewPass: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Gym icon/image
            if let profileImage = gym?.profileImage {
                AsyncImage(url: profileImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    gymIconPlaceholder
                }
            } else {
                gymIconPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gym?.name ?? "Gravity Gym")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.appTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(distance ?? "780m away")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.appTextLight)
            }
            
            Spacer()
            
            // QR Code Button
            Button(action: onViewPass) {
                Image(systemName: "qrcode")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.appPrimary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(Color(AppTheme.appContentBG))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 2, y: 2)    }
    
    private var gymIconPlaceholder: some View {
        Circle()
            .fill(AppTheme.appSecondary.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "figure.climbing")
                    .font(.title2)
                    .foregroundColor(AppTheme.appSecondary)
            )
    }
}

struct AddPassButton: View {
    let onAddPass: () -> Void
    
    var body: some View {
        Button(action: onAddPass) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Add pass")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(AppTheme.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 2, y: 2)
        }
    }
}

// Example usage in a parent view
struct NearbyGymRow: View {
    let gym: Gym?
    let distance: String?
    let onViewPass: () -> Void
    let onAddPass: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            NearbyGymCard(
                gym: gym,
                distance: distance,
                onViewPass: onViewPass
            )
            
            AddPassButton(onAddPass: onAddPass)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Preview with the new separated components
        NearbyGymRow(
            gym: SampleData.gyms[0], // Boulder World
            distance: "780m away",
            onViewPass: {
                print("View Pass tapped for \(SampleData.gyms[0].name)")
            },
            onAddPass: {
                print("Add Pass tapped for \(SampleData.gyms[0].name)")
            }
        )
        
        NearbyGymRow(
            gym: SampleData.gyms[1], // Vertical Edge
            distance: "1.2km away",
            onViewPass: {
                print("View Pass tapped for \(SampleData.gyms[1].name)")
            },
            onAddPass: {
                print("Add Pass tapped for \(SampleData.gyms[1].name)")
            }
        )
        
        NearbyGymRow(
            gym: nil,
            distance: nil,
            onViewPass: {
                print("View Pass tapped for fallback gym")
            },
            onAddPass: {
                print("Add Pass tapped for fallback gym")
            }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
