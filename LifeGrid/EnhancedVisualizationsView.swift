//
//  EnhancedVisualizationsView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//

import SwiftUI
import Charts

// Main visualization view integrating all charts
struct EnhancedVisualizationsView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var selectedChartType: ChartType = .dailyScores
    @State private var selectedSprintItem: Sprint? = nil // Renamed from selectedSprint to avoid conflicts
    @State private var selectedDateRange: DateRange = .month
    
    // Available chart types
    enum ChartType: String, CaseIterable, Identifiable {
        case dailyScores = "Daily Scores"
        case activityDistribution = "Activity Distribution"
        case goalProgress = "Goal Progress"
        case weeklyComparison = "Weekly Comparison"
        
        var id: String { self.rawValue }
    }
    
    // Date range options
    enum DateRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        case all = "All Time"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .all: return 365 * 5 // Just a large number
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart type selector
                    Picker("Chart Type", selection: $selectedChartType) {
                        ForEach(ChartType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Date range selector
                    HStack {
                        Text("Time Range:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedDateRange) {
                            ForEach(DateRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal)
                    
                    // Sprint selector (if available)
                    if !sprintStore.sprints.isEmpty {
                        HStack {
                            Text("Sprint:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $selectedSprintItem) {
                                Text("All Sprints").tag(nil as Sprint?)
                                ForEach(sprintStore.sprints) { sprint in
                                    Text(sprint.name).tag(sprint as Sprint?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Display selected chart
                    selectedChartView
                        .frame(height: 350)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    
                    // Stats section
                    statsSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Detailed Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Selected chart view based on the chart type
    @ViewBuilder
    private var selectedChartView: some View {
        if #available(iOS 16.0, *) {
            switch selectedChartType {
            case .dailyScores:
                DailyScoresChart(
                    sprintStore: sprintStore,
                    selectedSprintItem: selectedSprintItem, // <- Updated to match the function definition
                    dateRange: selectedDateRange
                )
            case .activityDistribution:
                ActivityDistributionChart(
                    sprintStore: sprintStore,
                    selectedSprintItem: selectedSprintItem,
                    dateRange: selectedDateRange
                )
            case .goalProgress:
                GoalProgressChart(
                    sprintStore: sprintStore,
                    selectedSprintItem: selectedSprintItem,
                    dateRange: selectedDateRange
                )
            case .weeklyComparison:
                WeeklyComparisonChart(
                    sprintStore: sprintStore,
                    selectedSprintItem: selectedSprintItem,
                    dateRange: selectedDateRange
                )
            }
        } else {
            // Fallback for iOS 15
            Text("Charts require iOS 16 or later")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
    }
    
    // Stats section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.headline)
            
            // Get data
            let stats = calculateStats()
            
            // Create grid of stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Average Score",
                    value: String(format: "%.1f%%", stats.averageScore * 100),
                    trend: stats.scoreTrend,
                    icon: "chart.bar.fill"
                )
                
                StatCard(
                    title: "Completion Rate",
                    value: String(format: "%.1f%%", stats.completionRate * 100),
                    trend: stats.completionTrend,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(stats.currentStreak) days",
                    trend: stats.streakTrend > 0 ? .up : (stats.streakTrend < 0 ? .down : .neutral),
                    icon: "flame.fill"
                )
                
                StatCard(
                    title: "Weekly Average",
                    value: String(format: "%.1f hrs", stats.weeklyHours),
                    trend: stats.hoursTrend,
                    icon: "clock.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Calculate statistics
    private func calculateStats() -> (
        averageScore: Double,
        completionRate: Double,
        currentStreak: Int,
        weeklyHours: Double,
        scoreTrend: TrendDirection,
        completionTrend: TrendDirection,
        streakTrend: Int,
        hoursTrend: TrendDirection
    ) {
        // Default values
        let defaultStats = (
            averageScore: 0.0,
            completionRate: 0.0,
            currentStreak: 0,
            weeklyHours: 0.0,
            scoreTrend: TrendDirection.neutral,
            completionTrend: TrendDirection.neutral,
            streakTrend: 0,
            hoursTrend: TrendDirection.neutral
        )
        
        // Get date range
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -selectedDateRange.days, to: today) else {
            return defaultStats
        }
        
        // Filter efforts based on sprint and date range
        let filteredEfforts: [Effort]
        if let sprint = selectedSprintItem {
            filteredEfforts = sprintStore.effortsForSprint(sprint).filter { effort in
                let effortDate = calendar.startOfDay(for: effort.date)
                return effortDate >= startDate && effortDate <= today
            }
        } else {
            filteredEfforts = sprintStore.efforts.filter { effort in
                let effortDate = calendar.startOfDay(for: effort.date)
                return effortDate >= startDate && effortDate <= today
            }
        }
        
        // Not enough data
        if filteredEfforts.isEmpty {
            return defaultStats
        }
        
        // Calculate days in range
        let daysInRange = calendar.dateComponents([.day], from: startDate, to: today).day ?? 1
        
        // Calculate average daily score
        var dayScores: [Date: Double] = [:]
        for effort in filteredEfforts {
            let effortDate = calendar.startOfDay(for: effort.date)
            
            // Find the goal for this effort
            if let sprint = selectedSprintItem ?? sprintStore.sprints.first(where: { sprint in
                sprint.goals.contains(where: { $0.id == effort.goalId })
            }) {
                if let goal = sprint.goals.first(where: { $0.id == effort.goalId }) {
                    let dailyTarget = goal.targetHours
                    let progress = min(effort.hours / dailyTarget, 1.0)
                    let weightedScore = progress * goal.weight
                    
                    dayScores[effortDate, default: 0] += weightedScore
                }
            }
        }
        
        // Average score
        let averageScore = dayScores.values.reduce(0, +) / Double(max(1, dayScores.count))
        
        // Completion rate (days with efforts / total days)
        let completionRate = Double(dayScores.count) / Double(daysInRange)
        
        // Streak calculation
        var currentStreak = 0
        let datesToCheck = (0...daysInRange).compactMap { days in
            calendar.date(byAdding: .day, value: -days, to: today)
        }
        
        for date in datesToCheck {
            if dayScores[date, default: 0] > 0.3 { // Threshold for a productive day
                currentStreak += 1
            } else {
                break
            }
        }
        
        // Weekly hours
        let weeklyHours = filteredEfforts.reduce(0.0) { $0 + $1.hours } / Double(max(1, daysInRange / 7))
        
        // Calculate trends
        // For simplicity, compare current week/month with previous
        let midpoint = startDate.addingTimeInterval((today.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 2)
        
        let recentEfforts = filteredEfforts.filter { $0.date >= midpoint }
        let olderEfforts = filteredEfforts.filter { $0.date < midpoint }
        
        // Calculate scores for recent vs older period
        var recentScores: [Date: Double] = [:]
        var olderScores: [Date: Double] = [:]
        
        for effort in recentEfforts {
            let effortDate = calendar.startOfDay(for: effort.date)
            recentScores[effortDate, default: 0] += effort.hours
        }
        
        for effort in olderEfforts {
            let effortDate = calendar.startOfDay(for: effort.date)
            olderScores[effortDate, default: 0] += effort.hours
        }
        
        // Trend calculations
        let recentAvgScore = recentScores.values.reduce(0, +) / Double(max(1, recentScores.count))
        let olderAvgScore = olderScores.values.reduce(0, +) / Double(max(1, olderScores.count))
        
        let scoreTrend: TrendDirection
        if recentAvgScore > olderAvgScore * 1.05 {
            scoreTrend = .up
        } else if recentAvgScore < olderAvgScore * 0.95 {
            scoreTrend = .down
        } else {
            scoreTrend = .neutral
        }
        
        // Completion trend
        let recentCompletionRate = Double(recentScores.count) / Double(max(1, daysInRange / 2))
        let olderCompletionRate = Double(olderScores.count) / Double(max(1, daysInRange / 2))
        
        let completionTrend: TrendDirection
        if recentCompletionRate > olderCompletionRate * 1.05 {
            completionTrend = .up
        } else if recentCompletionRate < olderCompletionRate * 0.95 {
            completionTrend = .down
        } else {
            completionTrend = .neutral
        }
        
        // Streak trend (just the sign of the difference)
        let previousStreak = calculateStreakForPeriod(
            startDate: calendar.date(byAdding: .day, value: -daysInRange * 2, to: startDate) ?? startDate,
            endDate: startDate
        )
        let streakTrend = currentStreak - previousStreak
        
        // Hours trend
        let recentHours = recentEfforts.reduce(0.0) { $0 + $1.hours }
        let olderHours = olderEfforts.reduce(0.0) { $0 + $1.hours }
        
        let hoursTrend: TrendDirection
        if recentHours > olderHours * 1.05 {
            hoursTrend = .up
        } else if recentHours < olderHours * 0.95 {
            hoursTrend = .down
        } else {
            hoursTrend = .neutral
        }
        
        return (
            averageScore: averageScore,
            completionRate: completionRate,
            currentStreak: currentStreak,
            weeklyHours: weeklyHours,
            scoreTrend: scoreTrend,
            completionTrend: completionTrend,
            streakTrend: streakTrend,
            hoursTrend: hoursTrend
        )
    }

    // Helper function to calculate streak for a specific period
    private func calculateStreakForPeriod(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        
        var streak = 0
        let filteredEfforts: [Effort]
        
        if let sprint = selectedSprintItem {
            filteredEfforts = sprintStore.effortsForSprint(sprint).filter { effort in
                let effortDate = calendar.startOfDay(for: effort.date)
                return effortDate >= startDate && effortDate <= endDate
            }
        } else {
            filteredEfforts = sprintStore.efforts.filter { effort in
                let effortDate = calendar.startOfDay(for: effort.date)
                return effortDate >= startDate && effortDate <= endDate
            }
        }
        
        // Group efforts by date
        var effortsByDate: [Date: [Effort]] = [:]
        for effort in filteredEfforts {
            let effortDate = calendar.startOfDay(for: effort.date)
            if effortsByDate[effortDate] == nil {
                effortsByDate[effortDate] = [effort]
            } else {
                effortsByDate[effortDate]?.append(effort)
            }
        }
        
        // Sort dates from newest to oldest
        let sortedDates = effortsByDate.keys.sorted(by: >)
        
        // Calculate streak
        var previousDate: Date? = nil
        
        for date in sortedDates {
            if let prev = previousDate {
                let dayDifference = calendar.dateComponents([.day], from: date, to: prev).day ?? 0
                if dayDifference != 1 {
                    break
                }
            }
            
            streak += 1
            previousDate = date
        }
        
        return streak
    }
}

// Stat card component
struct StatCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(trend.color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Chart Components
// These are iOS 16+ only

// Daily Scores Chart
@available(iOS 16.0, *)
struct DailyScoresChart: View {
    let sprintStore: SprintStore
    let selectedSprintItem: Sprint?
    let dateRange: EnhancedVisualizationsView.DateRange
    
    // Generate chart data
    private var chartData: [DailyScoreData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard calendar.date(byAdding: .day, value: -dateRange.days, to: today) != nil else {
            return []
        }
        
        // Get all days in the date range
        let daysInRange = (0...dateRange.days).compactMap { days in
            calendar.date(byAdding: .day, value: -days, to: today)
        }.reversed()
        
        var result: [DailyScoreData] = []
        
        // For each day, calculate the score
        for date in daysInRange {
            let dayDate = calendar.startOfDay(for: date)
            
            // Get all efforts for this day
            let dayEfforts = selectedSprintItem == nil ?
                sprintStore.effortsForDate(dayDate) :
                sprintStore.effortsForDate(dayDate).filter { effort in
                    // Only include efforts for the selected sprint's goals
                    selectedSprintItem!.goals.contains(where: { $0.id == effort.goalId })
                }
            
            // If no efforts, add with zero score
            if dayEfforts.isEmpty {
                result.append(DailyScoreData(date: dayDate, score: 0))
                continue
            }
            
            // Calculate score
            var dayScore: Double = 0
            
            for effort in dayEfforts {
                // Find the goal for this effort
                if let sprint = selectedSprintItem ?? sprintStore.sprints.first(where: { sprint in
                    sprint.goals.contains(where: { $0.id == effort.goalId })
                }) {
                    if let goal = sprint.goals.first(where: { $0.id == effort.goalId }) {
                        let dailyTarget = goal.targetHours
                        let progress = min(effort.hours / dailyTarget, 1.0)
                        let weightedScore = progress * goal.weight
                        
                        dayScore += weightedScore
                    }
                }
            }
            
            // Add to result
            result.append(DailyScoreData(date: dayDate, score: min(1.0, dayScore)))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Progress Scores")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("No data available for the selected period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(chartData) { day in
                        BarMark(
                            x: .value("Date", day.date),
                            y: .value("Score", day.score)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    
                    // Add a reference line at 70% (good performance)
                    RuleMark(y: .value("Good", 0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(.green.opacity(0.7))
                    
                    // Add trend line
                    if let trendLine = calculateTrendLine() {
                        ForEach(trendLine) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Trend", point.score)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .foregroundStyle(.red.opacity(0.6))
                        }
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(doubleValue * 100))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                // Use simple date formatting that won't trigger calendar component issues
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Calculate trend line for the chart
    private func calculateTrendLine() -> [DailyScoreData]? {
        guard chartData.count >= 2 else { return nil }
        
        // Simple linear regression
        let n = Double(chartData.count)
        
        // X axis is days from start
        let calendar = Calendar.current
        let startDate = chartData.first!.date
        
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        for point in chartData {
            let dayDiff = calendar.dateComponents([.day], from: startDate, to: point.date).day ?? 0
            let x = Double(dayDiff)
            let y = point.score
            
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }
        
        // Calculate slope and intercept
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        // Create trend line points (just start and end)
        let startX = 0.0
        let endX = Double(dateRange.days)
        
        let firstDate = chartData.first!.date
        let lastDate = calendar.date(byAdding: .day, value: dateRange.days, to: firstDate) ?? firstDate

        let startY = intercept + slope * startX
        let endY = intercept + slope * endX

        return [
            DailyScoreData(date: firstDate, score: max(0, min(1, startY))),
            DailyScoreData(date: lastDate, score: max(0, min(1, endY)))
        ]
    }
}

// Data structure for daily score chart
struct DailyScoreData: Identifiable {
    var id = UUID()
    let date: Date
    let score: Double
}

// Activity Distribution Chart
@available(iOS 16.0, *)
struct ActivityDistributionChart: View {
    let sprintStore: SprintStore
    let selectedSprintItem: Sprint?
    let dateRange: EnhancedVisualizationsView.DateRange
    
    // Generate chart data
    private var chartData: [ActivityData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -dateRange.days, to: today) else {
            return []
        }
        
        // Filter efforts by date range and sprint
        let filteredEfforts: [Effort]
        if let sprint = selectedSprintItem {
            filteredEfforts = sprintStore.effortsForSprint(sprint).filter { effort in
                let effortDate = calendar.startOfDay(for: effort.date)
                return effortDate >= startDate && effortDate <= today
            }
        } else {
            filteredEfforts = sprintStore.efforts.filter { effort in
                let effortDate = calendar.startOfDay(for: effort.date)
                return effortDate >= startDate && effortDate <= today
            }
        }
        
        // Group by goal and calculate total hours
        var goalHours: [UUID: Double] = [:]
        var goalNames: [UUID: String] = [:]
        
        for effort in filteredEfforts {
            goalHours[effort.goalId, default: 0] += effort.hours
            
            // Find goal name if we don't have it yet
            if goalNames[effort.goalId] == nil {
                if let sprint = selectedSprintItem ?? sprintStore.sprints.first(where: { sprint in
                    sprint.goals.contains(where: { $0.id == effort.goalId })
                }) {
                    if let goal = sprint.goals.first(where: { $0.id == effort.goalId }) {
                        goalNames[effort.goalId] = goal.title
                    }
                }
            }
        }
        
        // Convert to chart data
        return goalHours.map { goalId, hours in
            ActivityData(
                goalId: goalId,
                goalName: goalNames[goalId] ?? "Unknown Goal",
                hours: hours
            )
        }.sorted { $0.hours > $1.hours }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Distribution")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("No data available for the selected period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(chartData) { activity in
                        SectorMark(
                            angle: .value("Hours", activity.hours),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Goal", activity.goalName))
                        .annotation(position: .overlay) {
                            Text(activity.hours, format: .number.precision(.fractionLength(1)))
                                .font(.caption)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                // Legend
                VStack(alignment: .leading) {
                    ForEach(chartData) { activity in
                        HStack {
                            Circle()
                                .fill(Color.blue) // This will be auto-colored by SwiftUI
                                .frame(width: 10, height: 10)
                            
                            Text(activity.goalName)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(activity.hours, specifier: "%.1f") hrs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("(\(Int((activity.hours / totalHours) * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // Total hours for percentage calculation
    private var totalHours: Double {
        chartData.reduce(0) { $0 + $1.hours }
    }
}

// Data structure for activity chart
struct ActivityData: Identifiable {
    var id = UUID()
    let goalId: UUID
    let goalName: String
    let hours: Double
}

// Goal Progress Chart
@available(iOS 16.0, *)
struct GoalProgressChart: View {
    let sprintStore: SprintStore
    let selectedSprintItem: Sprint?
    let dateRange: EnhancedVisualizationsView.DateRange
    
    private var chartData: [GoalProgressData] {
        // If no sprint selected, show nothing
        guard let sprint = selectedSprintItem else { return [] }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -dateRange.days, to: today) else {
            return []
        }
        
        // Filter efforts for this sprint and date range
        let filteredEfforts = sprintStore.effortsForSprint(sprint).filter { effort in
            let effortDate = calendar.startOfDay(for: effort.date)
            return effortDate >= startDate && effortDate <= today
        }
        
        // Calculate days in range (actual days with data)
        let daysSet = Set(filteredEfforts.map { calendar.startOfDay(for: $0.date) })
        let uniqueDays = daysSet.count
        
        // Group efforts by goal
        var goalHours: [UUID: Double] = [:]
        
        for effort in filteredEfforts {
            goalHours[effort.goalId, default: 0] += effort.hours
        }
        
        // Calculate progress for each goal
        var result: [GoalProgressData] = []
        
        for goal in sprint.goals {
            let loggedHours = goalHours[goal.id] ?? 0
            
            // Target hours (daily target * number of unique days with data)
            let targetHours = goal.targetHours * Double(uniqueDays)
            
            // Calculate progress
            let progress = targetHours > 0 ? min(loggedHours / targetHours, 1.0) : 0
            
            result.append(GoalProgressData(
                goalId: goal.id,
                goalTitle: goal.title,
                targetHours: targetHours,
                loggedHours: loggedHours,
                progress: progress
            ))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goal Progress")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("Please select a sprint to view goal progress")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(chartData) { goal in
                        BarMark(
                            x: .value("Goal", goal.goalTitle),
                            y: .value("Progress", goal.progress)
                        )
                        .foregroundStyle(by: .value("Goal", goal.goalTitle))
                    }
                    
                    // Target line
                    RuleMark(y: .value("Target", 1.0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(.secondary)
                        .annotation(position: .trailing) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                }
                .chartYScale(domain: 0...max(1.0, (chartData.map { $0.progress }.max() ?? 1.0) * 1.1))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(doubleValue * 100))%")
                            }
                        }
                    }
                }
                
                // Details table
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 100)),
                    GridItem(.flexible(minimum: 80)),
                    GridItem(.flexible(minimum: 80)),
                    GridItem(.flexible(minimum: 80))
                ], spacing: 8) {
                    // Header
                    Group {
                        Text("Goal").font(.caption).fontWeight(.medium)
                        Text("Target").font(.caption).fontWeight(.medium)
                        Text("Logged").font(.caption).fontWeight(.medium)
                        Text("Progress").font(.caption).fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                    
                    // Data rows
                    ForEach(chartData) { goal in
                        Text(goal.goalTitle).font(.caption)
                        Text("\(goal.targetHours, specifier: "%.1f") hrs").font(.caption)
                        Text("\(goal.loggedHours, specifier: "%.1f") hrs").font(.caption)
                        Text("\(Int(goal.progress * 100))%").font(.caption)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// Data structure for goal progress chart
struct GoalProgressData: Identifiable {
    var id = UUID()
    let goalId: UUID
    let goalTitle: String
    let targetHours: Double
    let loggedHours: Double
    let progress: Double
}

// Weekly Comparison Chart
@available(iOS 16.0, *)
struct WeeklyComparisonChart: View {
    let sprintStore: SprintStore
    let selectedSprintItem: Sprint?
    let dateRange: EnhancedVisualizationsView.DateRange
    
    // Generate chart data
    private var chartData: [WeeklyData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // We'll compare up to 8 weeks
        let weeksToCompare = min(8, dateRange.days / 7)
        
        // Create array of week start dates
        var weekStartDates: [Date] = []
        for i in 0..<weeksToCompare {
            if let weekStartDate = calendar.date(byAdding: .day, value: -(i * 7), to: today) {
                let weekStart = calendar.date(
                    from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStartDate)
                ) ?? weekStartDate
                
                weekStartDates.append(weekStart)
            }
        }
        
        // For each week, calculate total hours
        var result: [WeeklyData] = []
        
        for weekStart in weekStartDates {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            
            // Filter efforts for this week
            let weekEfforts: [Effort]
            if let sprint = selectedSprintItem {
                weekEfforts = sprintStore.effortsForSprint(sprint).filter { effort in
                    let effortDate = calendar.startOfDay(for: effort.date)
                    return effortDate >= weekStart && effortDate <= weekEnd
                }
            } else {
                weekEfforts = sprintStore.efforts.filter { effort in
                    let effortDate = calendar.startOfDay(for: effort.date)
                    return effortDate >= weekStart && effortDate <= weekEnd
                }
            }
            
            // Calculate total hours
            let totalHours = weekEfforts.reduce(0.0) { $0 + $1.hours }
            
            // Calculate average score
            var dayScores: [Date: Double] = [:]
            for effort in weekEfforts {
                let effortDate = calendar.startOfDay(for: effort.date)
                
                // Find the goal for this effort
                if let sprint = selectedSprintItem ?? sprintStore.sprints.first(where: { sprint in
                    sprint.goals.contains(where: { $0.id == effort.goalId })
                }) {
                    if let goal = sprint.goals.first(where: { $0.id == effort.goalId }) {
                        let dailyTarget = goal.targetHours
                        let progress = min(effort.hours / dailyTarget, 1.0)
                        let weightedScore = progress * goal.weight
                        
                        dayScores[effortDate, default: 0] += weightedScore
                    }
                }
            }
            
            // Average score
            let averageScore = dayScores.values.reduce(0, +) / Double(max(1, dayScores.count))
            
            // Format week label
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let weekLabel = "\(dateFormatter.string(from: weekStart))-\(dateFormatter.string(from: weekEnd))"
            
            result.append(WeeklyData(
                weekStart: weekStart,
                weekLabel: weekLabel,
                hours: totalHours,
                averageScore: averageScore
            ))
        }
        
        return result.reversed()  // Most recent week first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Comparison")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("No data available for weekly comparison")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(chartData) { week in
                        BarMark(
                            x: .value("Week", week.weekLabel),
                            y: .value("Hours", week.hours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple.opacity(0.7), .blue],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    
                    // Average hours line
                    RuleMark(y: .value("Average", averageHours))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(.gray)
                        .annotation(position: .top, alignment: .leading) {
                            Text("Avg: \(averageHours, specifier: "%.1f") hrs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    
                    // Add score line chart
                    ForEach(chartData) { week in
                        LineMark(
                            x: .value("Week", week.weekLabel),
                            y: .value("Score", week.averageScore * maxHours)
                        )
                        .foregroundStyle(.red)
                        .symbol {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .chartYScale(domain: 0...(maxHours * 1.1))
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(doubleValue, specifier: "%.0f") hrs")
                            }
                        }
                    }
                    
                    AxisMarks(position: .trailing, values: [0, maxHours * 0.25, maxHours * 0.5, maxHours * 0.75, maxHours]) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int((doubleValue / maxHours) * 100))%")
                            }
                        }
                        AxisGridLine()
                    }
                }
                
                // Legend
                HStack {
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 8)
                        Text("Hours")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Score %")
                            .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // Average hours
    private var averageHours: Double {
        let totalHours = chartData.reduce(0.0) { $0 + $1.hours }
        return chartData.isEmpty ? 0 : totalHours / Double(chartData.count)
    }
    
    // Maximum hours (for scaling)
    private var maxHours: Double {
        return max(20, chartData.map { $0.hours }.max() ?? 20)
    }
}

// Data structure for weekly chart
struct WeeklyData: Identifiable {
    var id = UUID()
    let weekStart: Date
    let weekLabel: String
    let hours: Double
    let averageScore: Double
}


extension SprintStore {
    static var mock: SprintStore {
        let store = SprintStore()
        // TODO populate with fake sprints/goals/efforts for realistic preview
        return store
    }
}

#Preview {
    EnhancedVisualizationsView()
        .environmentObject(SprintStore.mock) // Replace with your real or mock store
}
