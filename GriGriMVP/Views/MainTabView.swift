//
//  MainTabView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 19/12/2024.
//

import Foundation
import SwiftUI
import VisionKit

struct MainTabView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView(appState: appState)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            NavigationStack {
                PassesRootView()
            }
            .tabItem {
                Label("Passes", systemImage: "qrcode.viewfinder")
            }
            
            NavigationStack {
                GymsView(appState: appState)
            }
            .tabItem {
                Label("Gyms", systemImage: "building.2")
            }
        }
        .tint(AppTheme.appPrimary)
    }
}

#Preview {
    MainTabView(appState: AppState())
}
