//
//  AccountView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//
import SwiftUI
struct AccountView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section(header: Text("Preferences")) {
                Stepper("Years to view: \(userSettings.yearsToView)",
                        value: $userSettings.yearsToView,
                        in: 1...70)
            }
            Section(header: Text("Sprints")) {
                NavigationLink("Manage Sprints", destination: SprintsView())
            }
        }
        .navigationTitle("Account Settings")
    }
}
