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
    @State private var retryCount = 0

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
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let profileImageURL = gym?.profileImage?.url {
                // Use AsyncImage as fallback when no cached image exists
                AsyncImage(url: profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .onAppear {
                            // Cache the loaded image for future use
                            Task {
                                if let gymId = gym?.id {
                                    let result = await LocalImageCache.shared.cacheImage(for: gymId, from: profileImageURL)
                                    if case .failure(let error) = result {
                                        loadError = error
                                        print("⚠️ CachedGymImageView: Failed to cache image: \(error.localizedDescription)")
                                    }
                                    // Update cached image after caching
                                    await MainActor.run {
                                        cachedImage = LocalImageCache.shared.getCachedImage(for: gymId)
                                    }
                                }
                            }
                        }
                } placeholder: {
                    if isLoading {
                        loadingPlaceholderView
                    } else {
                        placeholderView
                    }
                }
                .onAppear {
                    isLoading = true
                }
                .onDisappear {
                    isLoading = false
                }
            } else {
                placeholderView
            }
        }
        // Stable ID that never changes
        .id("cached-gym-image-\(gym?.id ?? "no-gym")")
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
    @State private var retryCount = 0

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
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let profileImageURL = company?.profileImage?.url {
                // Use AsyncImage as fallback when no cached image exists
                AsyncImage(url: profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .onAppear {
                            // Cache the loaded image for future use
                            Task {
                                if let companyId = company?.id {
                                    let result = await LocalImageCache.shared.cacheImage(for: companyId, from: profileImageURL)
                                    if case .failure(let error) = result {
                                        loadError = error
                                        print("⚠️ CachedCompanyImageView: Failed to cache image: \(error.localizedDescription)")
                                    }
                                    // Update cached image after caching
                                    await MainActor.run {
                                        cachedImage = LocalImageCache.shared.getCachedImage(for: companyId)
                                    }
                                }
                            }
                        }
                } placeholder: {
                    if isLoading {
                        loadingPlaceholderView
                    } else {
                        placeholderView
                    }
                }
                .onAppear {
                    isLoading = true
                }
                .onDisappear {
                    isLoading = false
                }
            } else {
                placeholderView
            }
        }
        // Stable ID that never changes
        .id("cached-company-image-\(company?.id ?? "no-company")")
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
