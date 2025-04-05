//
//  SprintGridTimelineView.swift (Previously LifetimeGridView)
//  LifeGrid
//

import SwiftUI

struct SprintGridTimelineView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sprintStore: SprintStore
    
    @StateObject private var lifetimeStore: LifetimeGridStore
    @State private var zoomedDay: DayData? = nil
    @State private var selectedYear: Int? = nil
    @State private var expandedYears: Set<Int> = []
    @State private var showingEffortSheet = false
    @State private var selectedEffortDate: Date? = nil
    @State private var selectedEffort: Effort? = nil
    @State private var showingEffortEditor = false
    
    @Namespace private var animationNamespace
    
    init() {
        // We'll initialize the StateObject in init
        // This is needed because we need to pass dependencies
        // We'll properly connect to the actual instances in onAppear
        _lifetimeStore = StateObject(wrappedValue:
            LifetimeGridStore(
                userSettings: UserSettings(),
                sprintStore: SprintStore()
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    ZStack {
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                        .edgesIgnoringSafeArea(.top)
                        
                        VStack {
                            Text("Sprint Timeline")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            if let longestSprint = SprintProgressCalculator.findLongestSprint(in: sprintStore) {
                                Text("\(longestSprint.startDate, style: .date) to \(longestSprint.endDate, style: .date)")
                                    .foregroundColor(.white.opacity(0.9))
                            } else {
                                Text("Create a sprint to view timeline")
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    
                    // Sprint overview stats
                    sprintOverviewSection
                    
                    // Year tabs
                    if lifetimeStore.lifetimeData.isEmpty {
                        Text("No data available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        yearTabsView
                    }
                    
                    // Year details
                    if let year = selectedYear, let yearData = lifetimeStore.lifetimeData.first(where: { $0.year == year }) {
                        yearDetailView(for: yearData)
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
            .onAppear {
                // Connect to the actual environment objects
                lifetimeStore.userSettings = userSettings
                lifetimeStore.sprintStore = sprintStore
                
                // Regenerate the data using sprint-based approach
                lifetimeStore.generateSprintTimelineData()
                
                // Set default selected year to current year
                if selectedYear == nil {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    selectedYear = currentYear
                }
            }
            .overlay {
                // Zoom overlay if a day is tapped
                if let day = zoomedDay {
                    dayDetailOverlay(for: day)
                }
            }
            .sheet(isPresented: $showingEffortSheet, onDismiss: {
                // Regenerate data after logging effort
                lifetimeStore.generateSprintTimelineData()
            }) {
                if let date = selectedEffortDate,
                   let sprint = getSprintForDay(date) {
                    DatePickerEffortLoggingView(sprint: sprint, initialDate: date)
                        .environmentObject(sprintStore)
                }
            }
            // Second sheet for effort editing
            .sheet(isPresented: $showingEffortEditor) {
                if let effort = selectedEffort,
                   let sprint = getSprintForGoal(effort.goalId) {
                    NavigationStack {
                        EditEffortView(effort: effort, sprint: sprint)
                            .environmentObject(sprintStore)
                    }
                }
            }
        }
    }
    
    // Sprint overview statistics section - replaces life overview
    private var sprintOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sprint Overview")
                .font(.headline)
            
            if let longestSprint = SprintProgressCalculator.findLongestSprint(in: sprintStore) {
                // Get detailed sprint statistics for the longest sprint
                let sprintStats = SprintProgressCalculator.calculateSprintStats(
                    sprint: longestSprint
                )
                
                VStack(spacing: 12) {
                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Sprint Progress")
                                .font(.subheadline)
                            Spacer()
                            Text(sprintStats.formattedPercentCompleted)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background bar
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                // Progress bar
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: geometry.size.width * CGFloat(sprintStats.percentCompleted), height: 12)
                                    .cornerRadius(6)
                            }
                        }
                        .frame(height: 12)
                    }
                    
                    HStack(spacing: 16) {
                        // Days passed stats
                        VStack {
                            Text("\(sprintStats.daysPassed)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Days Passed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Days remaining stat
                        VStack {
                            Text("\(sprintStats.daysRemaining)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Days Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Week stats
                    HStack(spacing: 16) {
                        // Weeks stats
                        VStack {
                            Text("\(sprintStats.weeksPassed)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Weeks Passed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        
                        // Weeks remaining stat
                        VStack {
                            Text("\(sprintStats.weeksRemaining)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Weeks Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Sprint timespan
                    HStack(spacing: 16) {
                        // Sprint name
                        VStack {
                            Text(longestSprint.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            Text("Sprint Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        
                        // Total span
                        VStack {
                            Text("\(sprintStats.totalDays)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Total Days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
            } else {
                // No sprints available
                VStack {
                    Text("No Sprints Available")
                        .font(.headline)
                        .padding()
                    
                    Text("Create a sprint to see your progress timeline")
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
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Year tabs view for selecting different years (unchanged)
    private var yearTabsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Year")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(lifetimeStore.lifetimeData.sorted(by: { $0.year < $1.year })) { yearData in
                        Button {
                            selectedYear = yearData.year
                            // Expand this year automatically when selected
                            if !expandedYears.contains(yearData.year) {
                                expandedYears.insert(yearData.year)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(String(yearData.year))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                // Show average score if available
                                if let avgScore = yearData.averageScore {
                                    Text("\(Int(avgScore * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(selectedYear == yearData.year ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedYear == yearData.year ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func getSprintForGoal(_ goalId: UUID) -> Sprint? {
        return sprintStore.getSprintForGoal(goalId)
    }
    
    // Detail view for a specific year (unchanged)
    private func yearDetailView(for yearData: YearData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Year header
            HStack {
                Text(String(yearData.year))
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let avgScore = yearData.averageScore {
                    Text("Average: \(Int(avgScore * 100))%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Month accordion sections
            ForEach(yearData.groupByMonths()) { monthData in
                monthSection(for: monthData)
            }
        }
        .padding(.top)
    }
    
    // Month section with expandable grid (unchanged)
    private func monthSection(for monthData: MonthData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header button
            Button {
                toggleExpandedYear(monthData.year)
            } label: {
                HStack {
                    Text(monthData.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let avgScore = monthData.averageScore {
                        Text("\(Int(avgScore * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: isYearExpanded(monthData.year) ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            
            // Expandable month grid
            if isYearExpanded(monthData.year) {
                VStack(alignment: .leading, spacing: 4) {
                    // Days grid for this month
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                        spacing: 4
                    ) {
                        // Add day of week headers
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .frame(width: 30)
                                .foregroundColor(.secondary)
                        }

                        
                        // Calculate first weekday of the month for proper alignment
                        let firstDayOfMonth = monthData.days.first?.date ?? Date()
                        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
                        
                        // Add empty cells for proper alignment (offset by 1 since weekday is 1-7)
                        ForEach(1..<firstWeekday, id: \.self) { _ in
                            Color.clear
                                .frame(width: 30, height: 30)
                        }
                        
                        // Add day cells
                        ForEach(monthData.days) { day in
                            if day != zoomedDay {
                                dayCell(for: day)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            zoomedDay = day
                                        }
                                    }
                            } else {
                                Color.clear
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .padding(.horizontal)
    }
    
    // Day cell view (unchanged)
    private func dayCell(for day: DayData) -> some View {
        ZStack {
            Rectangle()
                .fill(day.color) // Use the extension property for consistent coloring
                .matchedGeometryEffect(id: day.id, in: animationNamespace)
                .frame(width: 30, height: 30)
                .cornerRadius(4)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        .cornerRadius(4)
                )
            
            // Show day number
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 10))
                .foregroundColor(day.textColor) // Use the extension property
                .opacity(0.8)
        }
    }
    
    // Day detail overlay when a day is tapped (unchanged)
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
                let dayEfforts = getDayEfforts(for: day.date)
                
                if dayEfforts.isEmpty {
                    Text("No efforts logged")
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Logged Efforts:")
                            .font(.headline)
                        
                        ForEach(dayEfforts) { effort in
                            Button(action: {
                                selectedEffort = effort
                                showingEffortEditor = true
                            }) {
                                HStack {
                                    Text(getGoalTitle(for: effort.goalId))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", effort.hours)) hrs")
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Log effort button (only if the day is part of a sprint)
                if getSprintForDay(day.date) != nil {
                    Button(action: {
                        selectedEffortDate = day.date
                        showingEffortSheet = true
                        zoomedDay = nil  // Close the overlay
                    }) {
                        Text("Log Effort")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 8)
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
    
    // Helper function to get day color based on score - No longer needed, using extension
    
    // Helper to get efforts for a specific day
    private func getDayEfforts(for date: Date) -> [Effort] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return sprintStore.efforts.filter { effort in
            let effortDay = calendar.startOfDay(for: effort.date)
            return calendar.isDate(effortDay, inSameDayAs: targetDay)
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
    
    // Helper to get a sprint that includes a specific date
    private func getSprintForDay(_ date: Date) -> Sprint? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return sprintStore.sprints.first { sprint in
            let sprintStart = calendar.startOfDay(for: sprint.startDate)
            let sprintEnd = calendar.startOfDay(for: sprint.endDate)
            return targetDay >= sprintStart && targetDay <= sprintEnd
        }
    }
    
    // Toggle expanded state for a year
    private func toggleExpandedYear(_ year: Int) {
        if expandedYears.contains(year) {
            expandedYears.remove(year)
        } else {
            expandedYears.insert(year)
        }
    }
    
    // Check if a year is expanded
    private func isYearExpanded(_ year: Int) -> Bool {
        expandedYears.contains(year)
    }
}


#Preview("SprintGridTimelineView Preview") {
    SprintGridTimelineView()
        .environmentObject(UserSettings.mock)
        .environmentObject(SprintStore.mock)
}
