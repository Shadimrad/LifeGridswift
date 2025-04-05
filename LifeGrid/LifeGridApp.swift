//
//  LifeGridApp.swift (Renamed to SprintGridApp)
//  LifeGrid
//  (Modified to remove age-based UI and focus on sprints)
//

import SwiftUI

@main
struct SprintGridApp: App {
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
                    // Sprint View - shows currently active sprint
                    NavigationStack {
                        SprintGridMainView()
                            .environmentObject(userSettings)
                            .environmentObject(sprintStore)
                    }
                    .tabItem {
                        Label("Sprint View", systemImage: "chart.bar.fill")
                    }
                    
                    // Timeline View - shows all sprints in a timeline
                    NavigationStack {
                        SprintGridTimelineView()
                            .environmentObject(userSettings)
                            .environmentObject(sprintStore)
                    }
                    .tabItem {
                        Label("Timeline", systemImage: "calendar")
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
                            .environmentObject(sprintStore)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
    }
}


extension UserSettings {
    static var mockFirstLaunch: UserSettings {
        let settings = UserSettings()
        settings.isFirstLaunch = true
        return settings
    }

    static var mockReturningUser: UserSettings {
        let settings = UserSettings()
        settings.isFirstLaunch = false
        return settings
    }
}


#Preview("First Launch") {
    OnboardingView()
        .environmentObject(UserSettings.mockFirstLaunch)
        .environmentObject(SprintStore.mock)
}

#Preview("Main Tab View") {
    TabView {
        NavigationStack {
            SprintGridMainView()
        }
        .tabItem {
            Label("Sprint View", systemImage: "chart.bar.fill")
        }

        NavigationStack {
            SprintGridTimelineView()
        }
        .tabItem {
            Label("Timeline", systemImage: "calendar")
        }

        NavigationStack {
            SprintsView()
        }
        .tabItem {
            Label("Sprints", systemImage: "list.bullet")
        }

        NavigationStack {
            AccountView()
        }
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
    }
    .environmentObject(UserSettings.mockReturningUser)
    .environmentObject(SprintStore.mock)
}
