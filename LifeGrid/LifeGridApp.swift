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
                MainView()
                    .environmentObject(userSettings)
                    .environmentObject(sprintStore)
            }
        }
    }
}
