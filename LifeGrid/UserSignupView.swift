//
//  UserSignupView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//

import SwiftUI

struct UserSignupView: View {
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var targetAge: Int = 85
    @State private var showingPreview = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Welcome to LifeGrid")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Start tracking your life's journey")
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
                        
                        // Date of birth
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.headline)
                            
                            DatePicker(
                                "Select your birth date",
                                selection: $birthDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxHeight: 180)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        
                        // Target age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How long do you want to live? (in years)")
                                .font(.headline)
                            
                            HStack {
                                Text("\(targetAge) years")
                                    .frame(width: 100, alignment: .leading)
                                
                                Slider(value: Binding(
                                    get: { Double(targetAge) },
                                    set: { targetAge = Int($0) }
                                ), in: 50...120, step: 1)
                            }
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
                        Text("Preview Life Grid")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingPreview) {
                        LifeGridPreview(
                            birthDate: birthDate,
                            targetAge: targetAge
                        )
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
        // Calculate current age
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let currentAge = ageComponents.year ?? 0
        
        // Save settings
        userSettings.currentAge = currentAge
        userSettings.targetAge = targetAge
        userSettings.isFirstLaunch = false
        
        // Save name and email
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(birthDate, forKey: "userBirthDate")
        
        // Dismiss the view
        dismiss()
    }
}

struct LifeGridPreview: View {
    let birthDate: Date
    let targetAge: Int
    @Environment(\.dismiss) var dismiss
    
    // Calculate current age
    private var currentAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // Generate grid data
    private var gridData: [WeekData] {
        var result: [WeekData] = []
        
        // Calculate total weeks
        let totalWeeks = targetAge * 52
        
        // Calculate weeks lived so far
        let calendar = Calendar.current
        let weeksLived = calendar.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0
        
        // Generate week data
        for i in 0..<totalWeeks {
            let isLived = i < weeksLived
            result.append(WeekData(id: i, isLived: isLived))
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Life in Weeks")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Age \(currentAge) to \(targetAge)")
                            .foregroundColor(.secondary)
                        
                        // Calculate progress
                        let progress = Double(currentAge) / Double(targetAge)
                        
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
                                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        .padding(.vertical, 8)
                        
                        // Stats row
                        HStack {
                            VStack {
                                Text("\(currentAge)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Years Lived")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(targetAge - currentAge)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Years Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(Int(progress * 100))%")
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
                        Text("Life Grid")
                            .font(.headline)
                        
                        Text("Each box represents one week of your life")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Grid layout
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 52)
                        
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(gridData) { week in
                                Rectangle()
                                    .fill(getWeekColor(week))
                                    .frame(height: 8)
                                    .cornerRadius(1)
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
            .navigationTitle("Life Preview")
            .toolbar {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    // Get color for week box
    private func getWeekColor(_ week: WeekData) -> Color {
        if week.isLived {
            return Color.green.opacity(0.7)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// Week data model
struct WeekData: Identifiable {
    let id: Int
    let isLived: Bool
}

struct UserSignupView_Previews: PreviewProvider {
    static var previews: some View {
        UserSignupView()
            .environmentObject(UserSettings())
    }
}
