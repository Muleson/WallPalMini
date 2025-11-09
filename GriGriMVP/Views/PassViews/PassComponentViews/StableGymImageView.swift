//
//  StableGymImageView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 23/09/2025.
//

import SwiftUI

// Gym image view with caching and network fallback
struct CachedGymImageView: View {
    private let gym: Gym?
    private let size: CGFloat
    @State private var cachedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError: CacheError?

    init(gym: Gym?, size: CGFloat) {
        self.gym = gym
        self.size = size

        // Initialize with cached image if available
        if let gymId = gym?.id {
            self._cachedImage = State(initialValue: LocalImageCache.shared.getCachedImage(for: gymId))
        } else {
            self._cachedImage = State(initialValue: nil)
        }
    }

    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                // Show cached image
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                // Show loading state
                loadingPlaceholderView
            } else {
                // Show placeholder when no image available
                placeholderView
            }
        }
        // Stable ID that never changes
        .id("cached-gym-image-\(gym?.id ?? "no-gym")")
        .task {
            // Trigger image loading if not cached and URL exists
            guard cachedImage == nil,
                  let gymId = gym?.id,
                  let profileImageURL = gym?.profileImage?.url else {
                return
            }

            isLoading = true

            // Download and cache the image
            let result = await LocalImageCache.shared.cacheImage(for: gymId, from: profileImageURL)

            if case .failure(let error) = result {
                loadError = error
                print("⚠️ CachedGymImageView: Failed to cache image: \(error.localizedDescription)")
            }

            // Update UI with cached image
            cachedImage = LocalImageCache.shared.getCachedImage(for: gymId)
            isLoading = false
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.appPrimary.opacity(0.15))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Image(systemName: "building.2.fill")
                    .font(.system(size: size * 0.43, weight: .medium))
                    .foregroundColor(AppTheme.appPrimary)
            )
    }
    
    private var loadingPlaceholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.appPrimary.opacity(0.15))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.appPrimary))
                    .scaleEffect(0.8)
            )
    }
}

// Company image view with caching and network fallback
struct CachedCompanyImageView: View {
    private let company: GymCompany?
    private let size: CGFloat
    @State private var cachedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError: CacheError?

    init(company: GymCompany?, size: CGFloat) {
        self.company = company
        self.size = size

        // Initialize with cached image if available
        if let companyId = company?.id {
            self._cachedImage = State(initialValue: LocalImageCache.shared.getCachedImage(for: companyId))
        } else {
            self._cachedImage = State(initialValue: nil)
        }
    }

    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                // Show cached image
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                // Show loading state
                loadingPlaceholderView
            } else {
                // Show placeholder when no image available
                placeholderView
            }
        }
        // Stable ID that never changes
        .id("cached-company-image-\(company?.id ?? "no-company")")
        .task {
            // Trigger image loading if not cached and URL exists
            guard cachedImage == nil,
                  let companyId = company?.id,
                  let profileImageURL = company?.profileImage?.url else {
                return
            }

            isLoading = true

            // Download and cache the image
            let result = await LocalImageCache.shared.cacheImage(for: companyId, from: profileImageURL)

            if case .failure(let error) = result {
                loadError = error
                print("⚠️ CachedCompanyImageView: Failed to cache image: \(error.localizedDescription)")
            }

            // Update UI with cached image
            cachedImage = LocalImageCache.shared.getCachedImage(for: companyId)
            isLoading = false
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.appPrimary.opacity(0.15))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Image(systemName: "building.2.fill")
                    .font(.system(size: size * 0.43, weight: .medium))
                    .foregroundColor(AppTheme.appPrimary)
            )
    }
    
    private var loadingPlaceholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.appPrimary.opacity(0.15))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.appPrimary))
                    .scaleEffect(0.8)
            )
    }
}
