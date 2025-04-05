//
//  UserSignupView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

struct UserSignupView: View {
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showingPreview = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Welcome to SprintGrid")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track your progress sprint by sprint")
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.headline)
                            
                            TextField("Enter your name", text: $name)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                            
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preview button
                    Button {
                        showingPreview = true
                    } label: {
                        Text("Preview Sprint Grid")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingPreview) {
                        SprintGridPreview()
                    }
                    
                    // Get started button
                    Button {
                        saveUserSettings()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Save user settings
    private func saveUserSettings() {
        // Save settings without age-related data
        userSettings.isFirstLaunch = false
        
        // Save name and email
        userSettings.userName = name
        userSettings.userEmail = email
        userSettings.saveSettings()
        
        // Dismiss the view
        dismiss()
    }
}

// Sprint Grid Preview
struct SprintGridPreview: View {
    @Environment(\.dismiss) var dismiss
    
    // Sample sprint data for demo
    let sampleSprint = Sprint(
        name: "Sample Sprint",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
        goals: [
            Goal(title: "Coding", targetHours: 2.0, weight: 0.4),
            Goal(title: "Exercise", targetHours: 1.0, weight: 0.3),
            Goal(title: "Reading", targetHours: 1.0, weight: 0.3)
        ]
    )
    
    // Generate sample data for grid
    private var gridData: [DayData] {
        var result: [DayData] = []
        
        // Generate 14 days of sample data
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        
        for i in 0..<14 {
            if let day = calendar.date(byAdding: .day, value: i, to: startDate) {
                // Random score for sample data
                let score = i < 5 ? Double.random(in: 0.3...1.0) : nil
                result.append(DayData(date: day, score: score))
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with sprint info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Sprint View")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(sampleSprint.startDate, style: .date) to \(sampleSprint.endDate, style: .date)")
                            .foregroundColor(.secondary)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: geometry.size.width * 0.35, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        .padding(.vertical, 8)
                        
                        // Stats row
                        HStack {
                            VStack {
                                Text("5")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Days Logged")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("9")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Days Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("35%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Grid visualization
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sprint Grid")
                            .font(.headline)
                        
                        Text("Each box represents one day of your sprint")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Grid layout
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
                        
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(gridData) { day in
                                Rectangle()
                                    .fill(day.score != nil ?
                                          Color.green.opacity(0.7 * (day.score ?? 0)) :
                                          Color.gray.opacity(0.2))
                                    .frame(height: 40)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Preview")
            .toolbar {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

struct UserSignupView_Previews: PreviewProvider {
    static var previews: some View {
        UserSignupView()
            .environmentObject(UserSettings())
    }
}
