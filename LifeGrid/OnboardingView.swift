//
//  OnboardingView.swift
//  LifeGrid
//  (Modified to remove age-based onboarding)
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var currentStep = 0
    @State private var showingSprintCreation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            if currentStep == 0 {
                welcomeView
            } else if currentStep == 1 {
                userDetailsView
            } else {
                finalStepView
            }
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < 2 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 500)
        .sheet(isPresented: $showingSprintCreation) {
            NavigationStack {
                SprintsView()
                    .environmentObject(sprintStore)
            }
        }
    }
    
    // Welcome view (step 0)
    private var welcomeView: some View {
        VStack(spacing: 24) {
            Text("Welcome to Sprint Grid!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
            
            Text("Your personal sprint planning and tracking tool")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    iconName: "square.grid.3x3.fill",
                    title: "Sprint Grid",
                    description: "Visualize your sprints day by day"
                )
                
                FeatureRow(
                    iconName: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "Track your goal completion and daily progress"
                )
                
                FeatureRow(
                    iconName: "calendar.badge.plus",
                    title: "Sprint Planning",
                    description: "Plan and organize sprints with multiple goals"
                )
            }
            .padding()
        }
    }
    
    // User details view (step 1)
    private var userDetailsView: some View {
        VStack(spacing: 24) {
            Text("Tell us about yourself")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.headline)
                
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
                
                Text("Email (Optional)")
                    .font(.headline)
                
                TextField("Enter your email", text: $userEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding()
            
            Text("This information helps personalize your experience in the app.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // Final step view (step 2)
    private var finalStepView: some View {
        VStack(spacing: 24) {
            Text("You're all set!")
                .font(.title)
                .fontWeight(.bold)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding()
            
            Text("After you complete setup, you can create your first sprint and start tracking your progress.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Create Your First Sprint") {
                showingSprintCreation = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
    
    // Feature row component
    private struct FeatureRow: View {
        let iconName: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // Complete onboarding and move to main app
    private func completeOnboarding() {
        // Save user information
        userSettings.userName = userName.isEmpty ? "User" : userName
        userSettings.userEmail = userEmail
        
        // Mark first launch as complete
        userSettings.isFirstLaunch = false
        userSettings.saveSettings()
    }
}

#Preview("OnboardingView") {
    OnboardingView()
        .environmentObject(UserSettings.mockFirstLaunch)
        .environmentObject(SprintStore.mock)
}
