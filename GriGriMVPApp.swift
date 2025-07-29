//
//  GriGriMVPApp.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
    return true
  }
}

@main
struct YourApp: App {
   // register app delegate for Firebase setup
   @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Register custom URL protocol for local assets
        #if USE_LOCAL_DATA
        URLProtocol.registerClass(LocalAssetURLProtocol.self)
        #endif
    }

  var body: some Scene {
    WindowGroup {
      NavigationView {
          RootView()
              .preferredColorScheme(.light)
      }
    }
  }
}
