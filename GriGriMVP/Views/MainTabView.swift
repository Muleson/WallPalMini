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
                PassesRootView(appState: appState)
            }
            .tabItem {
                Label("Passes", systemImage: "qrcode.viewfinder")
            }
            
            NavigationStack {
                UpcomingEventsView(appState: appState)
            }
            .tabItem {
                Label("What's On", systemImage: "calendar.badge.clock")
            }
            
            NavigationStack {
                GymsListView(appState: appState)
            }
            .tabItem {
                Label("Gyms", systemImage: "building.2")
            }
        }
        .tint(AppTheme.appPrimary)
                .onAppear {
            print("📱 MainTabView.onAppear() called")
        }
    }
}


#Preview {
    MainTabView(appState: AppState())
}
