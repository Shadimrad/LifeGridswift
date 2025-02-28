//
//  OnboardingView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var ageInput: String = ""
    @State private var targetAgeInput: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to LifeGrid!")
                .font(.largeTitle)
            TextField("Your current age", text: $ageInput)
                .keyboardType(.numberPad)
            TextField("Until what age to view?", text: $targetAgeInput)
                .keyboardType(.numberPad)
            Button("Continue") {
                if let currentAge = Int(ageInput), let targetAge = Int(targetAgeInput) {
                    userSettings.currentAge = currentAge
                    userSettings.targetAge = targetAge
                    userSettings.isFirstLaunch = false
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
