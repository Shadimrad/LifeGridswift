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
    @State private var showingSprintDetail = false
    
    @Namespace private var animationNamespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section with sprint info instead of years
                    ZStack {
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                        .edgesIgnoringSafeArea(.top)
                        VStack {
                            Text("Sprint Grid")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            if let totalDays = getTotalSprintDays() {
                                Text("\(totalDays) Sprint Days Available")
                                    .foregroundColor(.white.opacity(0.9))
                            } else {
                                Text("No Sprints Available")
                                    .foregroundColor(.white.opacity(0.9))
                            }
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
    
    // Helper to get total days across all sprints
    private func getTotalSprintDays() -> Int? {
        guard !sprintStore.sprints.isEmpty else { return nil }
        
        let calendar = Calendar.current
        var totalDays = 0
        
        for sprint in sprintStore.sprints {
            if let days = calendar.dateComponents([.day], from: sprint.startDate, to: sprint.endDate).day {
                totalDays += days + 1 // +1 because both start and end dates are inclusive
            }
        }
        
        return totalDays
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
                Button(action: {
                    if let sprint = selectedSprint {
                        showingSprintDetail = true
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
            
            // Sprint progress
            let progress = calculateSprintProgress(sprint)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.vertical, 4)
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
    
    // Calculate sprint progress for a specific sprint
    private func calculateSprintProgress(_ sprint: Sprint) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let sprintEnd = calendar.startOfDay(for: sprint.endDate)
        
        // If sprint hasn't started, progress is 0
        if today < sprintStart {
            return 0.0
        }
        
        // If sprint is finished, progress is 100%
        if today > sprintEnd {
            return 1.0
        }
        
        // Calculate elapsed days / total days
        guard let totalDays = calendar.dateComponents([.day], from: sprintStart, to: sprintEnd).day,
              let elapsedDays = calendar.dateComponents([.day], from: sprintStart, to: today).day else {
            return 0.0
        }
        
        return totalDays > 0 ? min(Double(elapsedDays) / Double(totalDays), 1.0) : 0.0
    }
    
    // Modified function to generate day data so that days with no efforts yield a nil score.
    private func generateDayData(for sprint: Sprint, with efforts: [Effort]) -> [DayData] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: sprint.startDate)
        guard let daysCount = calendar.dateComponents([.day], from: startDate, to: sprint.endDate).day.map({ $0 + 1 }) else {
            return []
        }
        
        var dayDataArray: [DayData] = []
        
        for i in 0..<daysCount {
            if let currentDate = calendar.date(byAdding: .day, value: i, to: startDate) {
                // Filter efforts for the current date
                let dayEfforts = efforts.filter { effort in
                    let effortDay = calendar.startOfDay(for: effort.date)
                    return effortDay == currentDate
                }
                
                // If no efforts exist, leave score nil (so DayGridView can show a neutral color)
                // Otherwise, compute a score (for example, as a fraction of 24 hours logged)
                let score: Double? = dayEfforts.isEmpty ? nil : {
                    let totalHours = dayEfforts.reduce(0.0) { $0 + $1.hours }
                    return min(totalHours / 24.0, 1.0)
                }()
                
                dayDataArray.append(DayData(date: currentDate, score: score))
            }
        }
        
        return dayDataArray
    }
    
    // Detail overlay when a day is tapped
    private func dayDetailOverlay(for day: DayData) -> some View {
        ZStack {
            // Semi-transparent background to dismiss the overlay when tapped
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation { zoomedDay = nil }
                }
            
            // Overlay content card
            VStack(spacing: 16) {
                // Header showing the day’s date
                Text(day.date, style: .date)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Optional score if available
                if let score = day.score {
                    HStack {
                        Text("Day Score:")
                        Spacer()
                        Text("\(Int(score * 100))%")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Efforts logged for this day
                let dayEfforts = getEffortsForDay(day.date)
                if dayEfforts.isEmpty {
                    // When nothing is logged, show a message
                    Text("No efforts logged for this day.")
                        .foregroundColor(.secondary)
                } else {
                    // Otherwise, list the efforts
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
                
                // Button to add (log) effort for this day
                if let sprint = selectedSprint ?? sprintStore.sprints.first(where: { isDateInSprint(day.date, sprint: $0) }) {
                    Button(action: {
                        // Dismiss the overlay and navigate to the sprint detail view
                        withAnimation { zoomedDay = nil }
                        selectedSprint = sprint
                        showingSprintDetail = true
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
                
                // Close button to dismiss the overlay
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
