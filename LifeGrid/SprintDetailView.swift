//
//  SprintDetailView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/27/25.
//  (Updated to use DatePickerEffortLoggingView)
//

import SwiftUI

struct SprintDetailView: View {
    let sprint: Sprint
    @State private var showingEffortSheet = false
    @State private var showingEffortEditor = false
    @State private var selectedEffort: Effort? = nil
    @EnvironmentObject var sprintStore: SprintStore
    @State private var selectedDate = Date()
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sprint header
                VStack(spacing: 8) {
                    Text(sprint.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(sprint.startDate, style: .date) - \(sprint.endDate, style: .date)")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Goals section
                if sprint.goals.isEmpty {
                    Text("No goals defined for this sprint.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goals")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(sprint.goals) { goal in
                            goalCard(for: goal)
                        }
                    }
                }
                
                // Progress section - displays the grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sprint Progress")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Generate a grid for this sprint
                    let dayData = generateDayData(for: sprint, with: sprintStore.effortsForSprint(sprint))
                    
                    if dayData.isEmpty {
                        Text("No days to display.")
                            .foregroundColor(.gray)
                    } else {
                        sprintGridView(dayData: dayData)
                    }
                }
                .padding(.vertical)
                
                // Recent efforts section
                effortsListView
                
        
                // Log effort button
                Button(action: {
                    selectedDate = Date() // Default to today
                    showingEffortSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Effort")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingEffortSheet) {
                    DatePickerEffortLoggingView(sprint: sprint, initialDate: selectedDate)
                        .environmentObject(sprintStore)
                }

            }
            .padding()
        }
        .navigationTitle("Sprint Details")
        .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditSprintView(sprint: sprint)
                        .environmentObject(sprintStore)) {
                        Image(systemName: "pencil")
                    }
                }
            }
        .sheet(isPresented: $showingEffortSheet) {
            DatePickerEffortLoggingView(sprint: sprint, initialDate: selectedDate)
                .environmentObject(sprintStore)
                .sheet(isPresented: $showingEffortEditor) {
                    if let effort = selectedEffort {
                        NavigationStack {
                            EditEffortView(effort: effort, sprint: sprint)
                                .environmentObject(sprintStore)
                        }
                    }
                }
        }
        
    }
    
    // Goal card view
    private func goalCard(for goal: Goal) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                
                HStack {
                    Text("Target: \(goal.targetHours, specifier: "%.1f") hrs/day")
                    Text("•")
                    Text("Weight: \(Int(goal.weight * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress indicator
            let progress = calculateProgressForGoal(goal)
            CircularProgressView(progress: progress)
                .frame(width: 40, height: 40)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    // Sprint grid view
    private func sprintGridView(dayData: [DayData]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Extract day of week headers to a separate function
            dayOfWeekHeaderView()
            
            // Days grid
            let weeks = groupByWeeks(dayData)
            
            ForEach(weeks.keys.sorted(), id: \.self) { weekIndex in
                if let weekDays = weeks[weekIndex] {
                    weekRowView(weekIndex: weekIndex, weekDays: weekDays, isFirstWeek: weekIndex == weeks.keys.sorted().first)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // Extract day of week header into a separate function
    private func dayOfWeekHeaderView() -> some View {
        HStack {
            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
            ForEach(0..<dayLabels.count, id: \.self) { index in
                Text(dayLabels[index])
                    .font(.caption)
                    .frame(width: 30)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, 8)
    }

    // Extract week row into a separate function
    private func weekRowView(weekIndex: Int, weekDays: [DayData], isFirstWeek: Bool) -> some View {
        HStack(spacing: 4) {
            Text("\(weekIndex)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .leading)
            
            // Calculate empty slots for first week
            if isFirstWeek {
                let firstDay = weekDays.first?.date ?? Date()
                let weekday = Calendar.current.component(.weekday, from: firstDay) - 1 // 0-based
                
                ForEach(0..<weekday, id: \.self) { _ in
                    Color.clear
                        .frame(width: 30, height: 30)
                }
            }
            
            // Actual day cells
            ForEach(weekDays) { day in
                dayCellView(for: day)
                    .onTapGesture {
                        // Set date for effort logging
                        selectedDate = day.date
                        showingEffortSheet = true
                    }
            }
        }
    }
    
    // Day cell view
    private func dayCellView(for day: DayData) -> some View {
        ZStack {
            Circle()
                .fill(day.score == nil ? Color.gray.opacity(0.2) : day.color) // Use gray for days with no score
                .frame(width: 30, height: 30)
            
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 10))
                .foregroundColor(day.textColor) // Use the extension property
        }
    }

    
    // Recent efforts list
    private var effortsListView: some View {
        let sprintEfforts = sprintStore.effortsForSprint(sprint)
            .sorted(by: { $0.date > $1.date }) // Most recent first
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Recent Efforts")
                .font(.headline)
                .padding(.horizontal)
            
            if sprintEfforts.isEmpty {
                Text("No efforts logged yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(sprintEfforts.prefix(5)) { effort in
                    effortRow(for: effort)
                }
                
                if sprintEfforts.count > 5 {
                    Text("+ \(sprintEfforts.count - 5) more efforts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    // Effort row view
    private func effortRow(for effort: Effort) -> some View {
        Button(action: {
            selectedEffort = effort
            showingEffortEditor = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let goal = sprint.goals.first(where: { $0.id == effort.goalId }) {
                        Text(goal.title)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Text("Unknown Goal")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Text(effort.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Text("\(effort.hours, specifier: "%.1f") hrs")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle()) // Ensures proper tap behavior
    }
    
    // Helper to calculate progress for a goal
    private func calculateProgressForGoal(_ goal: Goal) -> Double {
        let efforts = sprintStore.effortsForSprint(sprint).filter { $0.goalId == goal.id }
        
        // Calculate how many days have passed in the sprint
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        
        // Only consider days up to today or sprint end
        let endDate = min(today, calendar.startOfDay(for: sprint.endDate))
        
        guard let daysPassed = calendar.dateComponents([.day], from: sprintStart, to: endDate).day,
              daysPassed >= 0 else {
            return 0
        }
        
        // For a future sprint that hasn't started yet
        if daysPassed == 0 {
            return 0
        }
        
        // Calculate total hours logged
        let totalHoursLogged = efforts.reduce(0) { $0 + $1.hours }
        
        // Calculate target hours for days that have passed
        let targetHoursSoFar = goal.targetHours * Double(daysPassed + 1)
        
        // Calculate progress (capped at 100%)
        return min(totalHoursLogged / targetHoursSoFar, 1.0)
    }
    
    // Generate day data for the sprint
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
        
        // Get daily scores from the sprint
        let scores = sprint.dailyScores(for: sprintEfforts)
        
        var dayDataArray: [DayData] = []
        
        for i in 0..<daysCount {
            if let currentDate = calendar.date(byAdding: .day, value: i, to: startDate) {
                // Check if there are any efforts for this day
                let dayEfforts = sprintEfforts.filter { effort in
                    calendar.isDate(calendar.startOfDay(for: effort.date), inSameDayAs: currentDate)
                }
                
                // Only set a score if there are efforts for this day
                let score = dayEfforts.isEmpty ? nil : (i < scores.count ? scores[i] : nil)
                dayDataArray.append(DayData(date: currentDate, score: score))
            }
        }
        
        return dayDataArray
    }
    
    // Group days by week for grid display
    private func groupByWeeks(_ days: [DayData]) -> [Int: [DayData]] {
        var weekGroups: [Int: [DayData]] = [:]
        let calendar = Calendar.current
        
        // Get the first day of the sprint to calculate week offsets
        guard let firstDay = days.first?.date else { return [:] }
        let firstWeek = calendar.component(.weekOfYear, from: firstDay)
        
        for day in days {
            let weekOfYear = calendar.component(.weekOfYear, from: day.date)
            // Calculate a relative week number starting from 1
            let relativeWeek = weekOfYear >= firstWeek ?
                               weekOfYear - firstWeek + 1 :
                               (52 - firstWeek) + weekOfYear + 1 // Handle year boundary
            
            if weekGroups[relativeWeek] == nil {
                weekGroups[relativeWeek] = [day]
            } else {
                weekGroups[relativeWeek]?.append(day)
            }
        }
        
        // Sort days within each week
        for (week, weekDays) in weekGroups {
            weekGroups[week] = weekDays.sorted(by: { $0.date < $1.date })
        }
        
        return weekGroups
    }
    
    // Helper function to get day color based on score
    private func getDayColor(for day: DayData) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        
        if day.date > today {
            // Future day
            return Color.gray.opacity(0.2)
        } else if let score = day.score {
            // Day with score
            let hue: Double = 0.33 // Green hue
            let minBrightness: Double = 0.4
            let maxBrightness: Double = 0.95
            let minSaturation: Double = 0.5
            let maxSaturation: Double = 0.9
            
            // Linear interpolation: higher score gives higher saturation and lower brightness
            let brightness = maxBrightness - (maxBrightness - minBrightness) * score
            let saturation = minSaturation + (maxSaturation - minSaturation) * score
            
            return Color(hue: hue, saturation: saturation, brightness: brightness)
        } else {
            // Past day with no data
            return Color.gray.opacity(0.1)
        }
    }
}

// Circular progress view for goals
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(progressColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10))
                .fontWeight(.bold)
        }
        
    }
    
    // Color based on progress
    private var progressColor: Color {
        if progress < 0.3 {
            return .red
        } else if progress < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

struct SprintDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSprint = Sprint(
            name: "Sample Sprint",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            goals: [
                Goal(title: "Study", targetHours: 2.0, weight: 0.5),
                Goal(title: "Exercise", targetHours: 1.0, weight: 0.3)
            ]
        )
        
        return NavigationStack {
            SprintDetailView(sprint: sampleSprint)
                .environmentObject(SprintStore())
        }
    }
}
