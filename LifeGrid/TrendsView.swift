//
//  TrendsView.swift
//  LifeGrid
//
//  Created on 2/27/25.
//

import SwiftUI
import Charts

// Enum for time range selection
enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

// Weekly average data structure
struct WeeklyAverage: Identifiable {
    var id = UUID()
    var weekStart: Date
    var average: Double
}

// Goal performance data structure
struct GoalPerformance: Identifiable {
    var id = UUID()
    var goalTitle: String
    var performance: Double
}

struct TrendsView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingGoalPerformance: Bool = false
    @Namespace private var animationNamespace // Create namespace properly at the view level
    
    // Data calculated from the SprintStore
    private var dayDataArray: [DayData] {
        let today = Date()
        
        switch selectedTimeRange {
        case .week:
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            return sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        case .month:
            let startDate = Calendar.current.date(byAdding: .month, value: -1, to: today)!
            return sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        case .quarter:
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: today)!
            return sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        case .year:
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: today)!
            return sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        }
    }
    
    // Calculated weekly averages
    private var weeklyAverages: [WeeklyAverage] {
        let calendar = Calendar.current
        var weekGroups: [Int: [DayData]] = [:]
        
        // Group by week
        for day in dayDataArray {
            let weekOfYear = calendar.component(.weekOfYear, from: day.date)
            let year = calendar.component(.year, from: day.date)
            let weekKey = year * 100 + weekOfYear
            
            if weekGroups[weekKey] == nil {
                weekGroups[weekKey] = [day]
            } else {
                weekGroups[weekKey]?.append(day)
            }
        }
        
        // Calculate averages for each week
        return weekGroups.keys.sorted().compactMap { weekKey in
            guard let daysInWeek = weekGroups[weekKey] else { return nil }
            
            let daysWithScores = daysInWeek.filter { $0.score != nil }
            guard !daysWithScores.isEmpty else { return nil }
            
            let totalScore = daysWithScores.reduce(0.0) { $0 + ($1.score ?? 0) }
            let average = totalScore / Double(daysWithScores.count)
            
            // Get the first day of the week for display
            let firstDay = daysInWeek.min { $0.date < $1.date }?.date ?? Date()
            
            return WeeklyAverage(weekStart: firstDay, average: average)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Toggle between overall trends and goal performance
                Toggle("Show Goal Performance", isOn: $showingGoalPerformance)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Status Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status Overview")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                StatusCard(
                                    title: "Average",
                                    value: String(format: "%.1f", calculateAverage() * 100) + "%",
                                    trend: calculateTrend(),
                                    color: .blue
                                )
                                
                                StatusCard(
                                    title: "Streak",
                                    value: "\(calculateStreak()) days",
                                    trend: nil,
                                    color: .green
                                )
                                
                                StatusCard(
                                    title: "Completion",
                                    value: String(format: "%.1f", calculateCompletion() * 100) + "%",
                                    trend: nil,
                                    color: .orange
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        
                        if showingGoalPerformance {
                            // Goal performance chart
                            goalPerformanceChart
                        } else {
                            // Overall trends chart
                            trendsChart
                        }
                        
//                        // Heat Map for the selected period
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Activity Overview")
//                                .font(.headline)
//                                .padding(.horizontal)
//                            
//                            // Use the class-level namespace directly - FIX
//                            HeatMapView(
//                                dayData: dayDataArray,
//                                zoomedDay: .constant(nil),
//                                animationNamespace: animationNamespace // Use the class-level namespace
//                            )
//                            .frame(height: 200)
//                        }
//                        .padding()
//                        .background(Color(.systemBackground))
//                        .cornerRadius(12)
//                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Trends")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // Weekly trends chart
    private var trendsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Progress")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(weeklyAverages) { week in
                        LineMark(
                            x: .value("Week", dateToString(week.weekStart)), // FIX: use formatted string
                            y: .value("Average", week.average)
                        )
                        .foregroundStyle(Color.blue)
                        
                        PointMark(
                            x: .value("Week", dateToString(week.weekStart)), // FIX: use formatted string
                            y: .value("Average", week.average)
                        )
                        .foregroundStyle(Color.blue)
                    }
                    
                    // Add a trend line if we have enough data
                    if weeklyAverages.count > 1 {
                        let trendLine = calculateTrendLine(data: weeklyAverages)
                        if let startPoint = trendLine.first, let endPoint = trendLine.last {
                            LineMark(
                                x: .value("Week", dateToString(startPoint.weekStart)), // FIX: use formatted string
                                y: .value("Trend", startPoint.average)
                            )
                            .foregroundStyle(Color.red.opacity(0.6))
                            
                            LineMark(
                                x: .value("Week", dateToString(endPoint.weekStart)), // FIX: use formatted string
                                y: .value("Trend", endPoint.average)
                            )
                            .foregroundStyle(Color.red.opacity(0.6))
                        }
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 250)
            } else {
                // Fallback for iOS 15 and earlier
                Text("Charts require iOS 16 or later")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    // Goal performance chart
    private var goalPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goal Performance")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(getGoalPerformanceData()) { goalData in
                        BarMark(
                            x: .value("Goal", goalData.goalTitle),
                            y: .value("Performance", goalData.performance)
                        )
                        .foregroundStyle(by: .value("Goal", goalData.goalTitle))
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 250)
            } else {
                // Fallback for iOS 15 and earlier
                Text("Charts require iOS 16 or later")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    // Helper function to convert date to string format for charts
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    // Helper method to calculate the overall average
    private func calculateAverage() -> Double {
        let daysWithScores = dayDataArray.filter { $0.score != nil }
        guard !daysWithScores.isEmpty else { return 0 }
        
        let totalScore = daysWithScores.reduce(0.0) { $0 + ($1.score ?? 0) }
        return totalScore / Double(daysWithScores.count)
    }
    
    // Helper method to calculate trend direction
    private func calculateTrend() -> TrendDirection? {
        guard weeklyAverages.count >= 2 else { return nil }
        
        // Compare most recent week with previous week
        let mostRecentWeeks = Array(weeklyAverages.suffix(2))
        if mostRecentWeeks[1].average > mostRecentWeeks[0].average {
            return .up
        } else if mostRecentWeeks[1].average < mostRecentWeeks[0].average {
            return .down
        } else {
            return .neutral
        }
    }
    
    // Calculate a simple linear trend line
    private func calculateTrendLine(data: [WeeklyAverage]) -> [WeeklyAverage] {
        guard data.count >= 2 else { return data }
        
        // Sort by date
        let sortedData = data.sorted(by: { $0.weekStart < $1.weekStart })
        
        // Simple linear regression
        let n = Double(sortedData.count)
        
        // X values are the number of days since the first date
        let firstDate = sortedData.first!.weekStart
        let xValues = sortedData.map { Calendar.current.dateComponents([.day], from: firstDate, to: $0.weekStart).day ?? 0 }
        let yValues = sortedData.map { $0.average }
        
        // Convert Int values to Double explicitly to avoid type conversion errors
        let xValuesDouble = xValues.map { Double($0) }
        
        let sumX = xValuesDouble.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValuesDouble, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValuesDouble.map { $0 * $0 }.reduce(0, +)
        
        // Calculate slope and intercept
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Create start and end points for the trend line
        let startX = xValuesDouble.first ?? 0
        let endX = xValuesDouble.last ?? 0
        
        let startY = intercept + slope * startX
        let endY = intercept + slope * endX
        
        return [
            WeeklyAverage(weekStart: sortedData.first!.weekStart, average: max(0, min(1, startY))),
            WeeklyAverage(weekStart: sortedData.last!.weekStart, average: max(0, min(1, endY)))
        ]
    }
    
    // Helper method to calculate the current streak
    private func calculateStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort days by date in descending order (most recent first)
        let sortedDays = dayDataArray.sorted(by: { $0.date > $1.date })
        
        for day in sortedDays {
            let dayDate = calendar.startOfDay(for: day.date)
            
            // Stop at today or future dates
            if dayDate > today {
                continue
            }
            
            // Check if this day has a score and it's above a threshold (e.g., 0.4)
            if let score = day.score, score >= 0.4 {
                streak += 1
            } else {
                // Break streak if a day doesn't meet criteria
                break
            }
        }
        
        return streak
    }
    
    // Helper method to calculate completion percentage
    private func calculateCompletion() -> Double {
        let daysWithData = dayDataArray.filter { $0.score != nil }
        let pastDays = dayDataArray.filter { $0.date <= Date() }
        
        guard !pastDays.isEmpty else { return 0 }
        
        return Double(daysWithData.count) / Double(pastDays.count)
    }
    
    private func getGoalPerformanceData() -> [GoalPerformance] {
        // Collect all goals from all sprints that fall within the selected time range
        var goalPerformance: [UUID: (title: String, totalTarget: Double, totalLogged: Double)] = [:]
        
        // Get all unique sprints for the date range
        let days = dayDataArray
        let dates = days.map { $0.date }
        
        // Get all efforts for the date range
        let efforts = dates.flatMap { date in
            sprintStore.effortsForDate(date)
        }
        
        // Group efforts by goal
        for effort in efforts {
            // Find the goal this effort belongs to
            guard let goal = sprintStore.getGoalById(effort.goalId) else {
                continue
            }
            
            // Add goal data
            if let existingData = goalPerformance[goal.id] {
                let updatedLogged = existingData.totalLogged + effort.hours
                goalPerformance[goal.id] = (
                    title: existingData.title,
                    totalTarget: existingData.totalTarget + goal.targetHours,
                    totalLogged: updatedLogged
                )
            } else {
                goalPerformance[goal.id] = (
                    title: goal.title,
                    totalTarget: goal.targetHours,
                    totalLogged: effort.hours
                )
            }
        }
        
        // Calculate performance percentages
        return goalPerformance.map { (id, data) in
            let performance = data.totalTarget > 0 ? min(data.totalLogged / data.totalTarget, 1.0) : 0
            return GoalPerformance(id: id, goalTitle: data.title, performance: performance)
        }
    }
}

// Status card view for displaying metrics
struct StatusCard: View {
    let title: String
    let value: String
    let trend: TrendDirection?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let trend = trend {
                    Image(systemName: trendIcon(for: trend))
                        .foregroundColor(trendColor(for: trend))
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(minWidth: 100)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func trendIcon(for trend: TrendDirection) -> String {
        return trend.icon
    }
    
    private func trendColor(for trend: TrendDirection) -> Color {
        return trend.color
    }
}

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        let sprintStore = SprintStore()
        // Add some sample data to the store
        
        return TrendsView()
            .environmentObject(sprintStore)
    }
}
