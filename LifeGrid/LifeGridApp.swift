//
//  LifeGridApp.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

@main
struct LifeGridApp: App {
    @StateObject var userSettings = UserSettings()
    @StateObject var sprintStore = SprintStore()
    
    var body: some Scene {
        WindowGroup {
            if userSettings.isFirstLaunch {
                OnboardingView()
                    .environmentObject(userSettings)
                    .environmentObject(sprintStore)
            } else {
                // Use TabView to provide navigation between different views
                TabView {
                    // Daily Grid View - shows sprints
                    SprintGridMainView()
                        .environmentObject(userSettings)
                        .environmentObject(sprintStore)
                        .tabItem {
                            Label("Sprint View", systemImage: "chart.bar.fill")
                        }
                    
                    // Life Grid View - shows full lifespan
                    LifetimeGridView()
                        .environmentObject(userSettings)
                        .environmentObject(sprintStore)
                        .tabItem {
                            Label("Life Grid", systemImage: "calendar")
                        }
                    
                    // Sprints Management
                    NavigationStack {
                        SprintsView()
                            .environmentObject(sprintStore)
                    }
                    .tabItem {
                        Label("Sprints", systemImage: "list.bullet")
                    }
                    
                    // Settings
                    NavigationStack {
                        AccountView()
                            .environmentObject(userSettings)
                            .environmentObject(sprintStore) // <-- Add this line
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
    }
}
