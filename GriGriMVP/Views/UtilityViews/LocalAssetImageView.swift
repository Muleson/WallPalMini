//
//  LocalAssetImageView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import SwiftUI

struct LocalAssetImageView: View {
    let url: URL?
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = .fit) {
        self.url = url
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let url = url, url.scheme == "local-asset" {
                // Handle local assets
                let assetName = url.host ?? "sample-gym-1"
                Image(assetName, bundle: .main)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let url = url {
                // Handle regular URLs
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } placeholder: {
                    ProgressView()
                        .frame(width: 50, height: 50)
                }
            } else {
                // Fallback placeholder
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
            }
        }
    }
}

// MARK: - Extension for easy MediaItem usage
extension LocalAssetImageView {
    init(mediaItem: MediaItem?, contentMode: ContentMode = .fit) {
        self.init(url: mediaItem?.url, contentMode: contentMode)
    }
}
