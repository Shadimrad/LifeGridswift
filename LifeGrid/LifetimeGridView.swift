//
//  LifetimeGridView.swift (Fixed)
//

import SwiftUI

struct LifetimeGridView: View {
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
                            Text("LifeGrid")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            Text("Age \(userSettings.currentAge) to \(userSettings.targetAge)")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Life overview stats
                    lifeOverviewSection
                    
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
                
                // Regenerate the data
                lifetimeStore.generateLifetimeData()
                
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
            // FIXED: Removed duplicate sheet and fixed the placement
            .sheet(isPresented: $showingEffortSheet, onDismiss: {
                // Regenerate data after logging effort
                lifetimeStore.generateLifetimeData()
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
    
    // Life overview statistics section
    private var lifeOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Life Overview")
                .font(.headline)
            
            // Get detailed life statistics
            let lifeStats = LifeProgressCalculator.calculateLifeStats(
                currentAge: userSettings.currentAge,
                targetAge: userSettings.targetAge
            )
            
            VStack(spacing: 12) {
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Life Progress")
                            .font(.subheadline)
                        Spacer()
                        Text(lifeStats.formattedPercentCompleted)
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
                                .frame(width: geometry.size.width * CGFloat(lifeStats.percentCompleted), height: 12)
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                }
                
                HStack(spacing: 16) {
                    // Years stats
                    VStack {
                        Text("\(lifeStats.yearsLived)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Years Passed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Years remaining stat
                    VStack {
                        Text("\(lifeStats.yearsRemaining)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Years Remaining")
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
                        Text("\(lifeStats.weeksLived)")
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
                        Text("\(lifeStats.weeksRemaining)")
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
                
                // Days stats
                HStack(spacing: 16) {
                    // Days stats
                    VStack {
                        Text("\(lifeStats.daysLived)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Days Passed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Days remaining stat
                    VStack {
                        Text("\(lifeStats.daysRemaining)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Days Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Life percentage calculation
    private var lifePercentage: Double {
        let totalYears = Double(userSettings.targetAge)
        let currentAge = Double(userSettings.currentAge)
        return totalYears > 0 ? min(currentAge / totalYears, 1.0) : 0
    }
    
    // Year tabs view for selecting different years
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
                                Text("\(yearData.year)")
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
    
    // FIXED: Removed one of the duplicate getSprintForGoal functions
    private func getSprintForGoal(_ goalId: UUID) -> Sprint? {
        return sprintStore.getSprintForGoal(goalId)
    }
    
    // Detail view for a specific year
    private func yearDetailView(for yearData: YearData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Year header
            HStack {
                Text("\(yearData.year)")
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
    
    // Month section with expandable grid
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
    
    // Day cell view
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
    
    // Day detail overlay when a day is tapped
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
                                // Don't dismiss overlay yet - let the sheet do that
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
    
    // Helper function to get appropriate text color (dark or light) based on background
    private func getTextColor(for day: DayData) -> Color {
        if let score = day.score, score > 0.5 {
            // For dark backgrounds (high score), use white text
            return .white
        } else {
            // For light backgrounds (low/no score), use dark text
            return .primary
        }
    }
    
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
