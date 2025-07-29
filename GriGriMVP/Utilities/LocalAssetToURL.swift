//
//  LocalAssetToURL.swift
//  GriGriMVP
//
//  Created by Sam Quested on 28/07/2025.
//

import SwiftUI

// MARK: - Custom URL Session for handling local assets
class LocalAssetURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == "local-asset"
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let assetName = url.host else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "LocalAsset", code: 404, userInfo: nil))
            return
        }
        
        // Load image from bundle
        guard let image = UIImage(named: assetName),
              let imageData = image.pngData() else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "LocalAsset", code: 404, userInfo: nil))
            return
        }
        
        // Create response
        let response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: imageData.count, textEncodingName: nil)
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: imageData)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // Nothing to stop
    }
}

// MARK: - App Setup Extension
extension App {
    func configureLocalAssets() -> some Scene {
        // Register the custom URL protocol for local assets
        URLProtocol.registerClass(LocalAssetURLProtocol.self)
        
        return WindowGroup {
            NavigationView {
                RootView()
                    .preferredColorScheme(.light)
            }
        }
    }
}
