//
//  SprintGridMainView.swift
//  LifeGrid
//
//  Created on 2/28/25.
//

import SwiftUI

struct SprintGridMainView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var zoomedDay: DayData? = nil
    @State private var selectedSprint: Sprint? = nil
    @State private var showingSprintDetail = false  // Add this line
    
    @Namespace private var animationNamespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    ZStack {
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                        .edgesIgnoringSafeArea(.top)
                        VStack {
                            Text("LifeGrid")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            Text("Viewing \(userSettings.yearsToView) Years")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Sprint selector
                    if sprintStore.sprints.isEmpty {
                        createSprintPrompt
                    } else {
                        sprintPicker
                        
                        // Show selected sprint details and grid
                        if let sprint = selectedSprint ?? sprintStore.sprints.first {
                            sprintDetailsView(for: sprint)
                            
                            // Grid for the selected sprint
                            sprintGridView(for: sprint)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationLink("Account") {
                    AccountView()
                }
            }
            .sheet(isPresented: $showingSprintDetail) {
                if let sprint = selectedSprint {
                    SprintDetailView(sprint: sprint)
                        .environmentObject(sprintStore)
                }
            }
            .onAppear {
                // Set selected sprint to the first one if not already set
                if selectedSprint == nil && !sprintStore.sprints.isEmpty {
                    selectedSprint = sprintStore.sprints.first
                }
            }
            .overlay {
                // Zoom overlay if a day is tapped
                if let day = zoomedDay {
                    dayDetailOverlay(for: day)
                }
            }
        }
    }
    
    // Create sprint prompt for when no sprints exist
    private var createSprintPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Sprints Available")
                .font(.headline)
            
            Text("Create a sprint to start tracking your progress!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            NavigationLink(destination: SprintsView()) {
                Text("Create Sprint")
                    .fontWeight(.semibold)
                    .frame(width: 150)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Sprint picker for multiple sprints
    private var sprintPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Sprint")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sprintStore.sprints) { sprint in
                        Button {
                            selectedSprint = sprint
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sprint.name)
                                    .font(.headline)
                                
                                Text("\(sprint.startDate, style: .date) - \(sprint.endDate, style: .date)")
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 160, alignment: .leading)
                            .background(selectedSprint?.id == sprint.id ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedSprint?.id == sprint.id ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Sprint details view showing summary info
    private func sprintDetailsView(for sprint: Sprint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sprint header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sprint.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(sprint.startDate, style: .date) - \(sprint.endDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Log effort button
                // Log effort button
                Button(action: {
                    if let sprint = selectedSprint {
                        showingSprintDetail = true  // Just set the flag to true
                    }
                }) {
                    Text("Log Effort")
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Goals summary
            if !sprint.goals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goals")
                        .font(.headline)
                    
                    ForEach(sprint.goals) { goal in
                        HStack {
                            Text(goal.title)
                            Spacer()
                            Text("\(String(format: "%.1f", goal.targetHours)) hrs/day")
                                .foregroundColor(.secondary)
                            Text("(\(Int(goal.weight * 100))%)")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Grid view for a specific sprint
    private func sprintGridView(for sprint: Sprint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Grid")
                .font(.headline)
                .padding(.horizontal)
            
            let dayData = generateDayData(for: sprint, with: sprintStore.efforts)
            
            if dayData.isEmpty {
                Text("No days in sprint range")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                DayGridView(
                    dayData: dayData,
                    zoomedDay: $zoomedDay,
                    animationNamespace: animationNamespace
                )
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Function to generate day data for a sprint
    private func generateDayData(for sprint: Sprint, with efforts: [Effort]) -> [DayData] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: sprint.startDate)
        guard let daysCount = calendar.dateComponents([.day], from: startDate, to: sprint.endDate).day.map({ $0 + 1 }) else {
            return []
        }
        
        // Filter efforts only for this sprint
        let sprintEfforts = efforts.filter { effort in
            let effortDate = calendar.startOfDay(for: effort.date)
            return effortDate >= startDate && effortDate <= calendar.startOfDay(for: sprint.endDate)
        }
        
        let scores = sprint.dailyScores(for: sprintEfforts)
        var dayDataArray: [DayData] = []
        
        for i in 0..<daysCount {
            if let currentDate = calendar.date(byAdding: .day, value: i, to: startDate) {
                let score = i < scores.count ? scores[i] : nil
                dayDataArray.append(DayData(date: currentDate, score: score))
            }
        }
        
        return dayDataArray
    }
    
    // Detail overlay when a day is tapped
    private func dayDetailOverlay(for day: DayData) -> some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation { zoomedDay = nil }
                }
            
            // Day detail card
            VStack(spacing: 16) {
                // Header with date
                Text(day.date, style: .date)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Score if available
                if let score = day.score {
                    HStack {
                        Text("Day Score:")
                        Spacer()
                        Text("\(Int(score * 100))%")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                } else {
                    Text("No data logged for this day")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Efforts logged for this day
                let dayEfforts = getEffortsForDay(day.date)
                
                if dayEfforts.isEmpty {
                    Text("No efforts logged")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(dayEfforts) { effort in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(getGoalTitle(for: effort.goalId))
                                            .font(.headline)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", effort.hours)) hrs")
                                        .fontWeight(.medium)
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground).opacity(0.7))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(height: 150)
                }
                
                // Log effort button
                if let sprint = selectedSprint ?? sprintStore.sprints.first(where: { isDateInSprint(day.date, sprint: $0) }) {
                    Button(action: {
                        // Present the effort logging view for this day
                        zoomedDay = nil
                        
                        // Note: In a real implementation, you would present a sheet or navigation to log effort
                        // For now, we'll just close the overlay as we can't directly show a sheet from here
                    }) {
                        Text("Log Effort for This Day")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                // Close button
                Button("Close") {
                    withAnimation { zoomedDay = nil }
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(width: 300)
            .padding(.horizontal, 20)
        }
    }
    
    // Helper to get efforts for a specific day
    private func getEffortsForDay(_ date: Date) -> [Effort] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return sprintStore.efforts.filter { effort in
            let effortDay = calendar.startOfDay(for: effort.date)
            return effortDay == targetDay
        }
    }
    
    // Helper to get the goal title for an effort
    private func getGoalTitle(for goalId: UUID) -> String {
        for sprint in sprintStore.sprints {
            if let goal = sprint.goals.first(where: { $0.id == goalId }) {
                return goal.title
            }
        }
        return "Unknown Goal"
    }
    
    // Helper to check if a date is within a sprint's date range
    private func isDateInSprint(_ date: Date, sprint: Sprint) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let sprintEnd = calendar.startOfDay(for: sprint.endDate)
        
        return day >= sprintStart && day <= sprintEnd
    }
}

struct SprintGridMainView_Previews: PreviewProvider {
    static var previews: some View {
        SprintGridMainView()
            .environmentObject(UserSettings())
            .environmentObject(SprintStore())
    }
}
