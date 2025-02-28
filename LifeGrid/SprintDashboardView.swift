//
//  SprintDashboardView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//
import SwiftUI
import Charts

struct SprintDashboardView: View {
    @EnvironmentObject var sprintStore: SprintStore
    let sprint: Sprint
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sprint progress stats
                progressStatsView
                
                // Performance by goal
                goalPerformanceView
                
                // Trend analysis
                TrendAnalysisView()
                    .environmentObject(sprintStore)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Sprint progress statistics
    private var progressStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sprint Progress")
                .font(.headline)
            
            // Calculate progress metrics
            let metrics = calculateProgressMetrics()
            
            HStack(spacing: 16) {
                // Days completed
                ProgressStatCard(
                    title: "Days",
                    value: "\(metrics.daysCompleted) / \(metrics.totalDays)",
                    percentage: Double(metrics.daysCompleted) / Double(max(1, metrics.totalDays)),
                    icon: "calendar"
                )
                
                // Average daily score
                ProgressStatCard(
                    title: "Avg Score",
                    value: "\(Int(metrics.averageScore * 100))%",
                    percentage: metrics.averageScore,
                    icon: "chart.bar.fill"
                )
                
                // Completion rate
                ProgressStatCard(
                    title: "Completion",
                    value: "\(Int(metrics.completionRate * 100))%",
                    percentage: metrics.completionRate,
                    icon: "checkmark.circle.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Goal performance view
    private var goalPerformanceView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Performance")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                // Performance chart
                Chart {
                    ForEach(getGoalPerformance()) { goalData in
                        BarMark(
                            x: .value("Goal", goalData.title),
                            y: .value("Performance", goalData.performance)
                        )
                        .foregroundStyle(by: .value("Goal", goalData.title))
                    }
                    
                    RuleMark(y: .value("Target", 1.0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(.secondary)
                }
                .chartYScale(domain: 0...max(1.2, getGoalPerformance().map { $0.performance }.max() ?? 1.2))
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(doubleValue * 100))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 250)
            } else {
                // Fallback for iOS 15
                ForEach(getGoalPerformance()) { goalData in
                    HStack {
                        Text(goalData.title)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        ProgressBar(value: min(goalData.performance, 1.0))
                            .frame(width: 150, height: 12)
                        
                        Text("\(Int(goalData.performance * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Calculate progress metrics for this sprint
    private func calculateProgressMetrics() -> (daysCompleted: Int, totalDays: Int, averageScore: Double, completionRate: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let sprintEnd = calendar.startOfDay(for: sprint.endDate)
        
        // Calculate total days in sprint
        let totalDays = (calendar.dateComponents([.day], from: sprintStart, to: sprintEnd).day ?? 0) + 1
        
        // Calculate completed days (up to today or sprint end, whichever is earlier)
        let endDate = min(today, sprintEnd)
        let daysCompleted = max(0, (calendar.dateComponents([.day], from: sprintStart, to: endDate).day ?? 0) + 1)
        
        // Get sprint efforts and calculate daily scores
        let sprintEfforts = sprintStore.effortsForSprint(sprint)
        let dailyScores = sprint.dailyScores(for: sprintEfforts)
        
        // Calculate average score for completed days
        let completedDaysScores = Array(dailyScores.prefix(daysCompleted))
        let averageScore = completedDaysScores.isEmpty ? 0 : completedDaysScores.reduce(0, +) / Double(completedDaysScores.count)
        
        // Calculate completion rate (completed goals / total goals)
        let completionRate = calculateCompletionRate(sprintEfforts)
        
        return (daysCompleted, totalDays, averageScore, completionRate)
    }
    
    // Calculate completion rate based on goal targets
    private func calculateCompletionRate(_ efforts: [Effort]) -> Double {
        var goalHoursLogged: [UUID: Double] = [:]
        var goalTargetHours: [UUID: Double] = [:]
        
        // Calculate days elapsed in sprint
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let daysElapsed = max(1, (calendar.dateComponents([.day], from: sprintStart, to: min(today, sprint.endDate)).day ?? 0) + 1)
        
        // Initialize target hours for each goal
        for goal in sprint.goals {
            goalTargetHours[goal.id] = goal.targetHours * Double(daysElapsed)
            goalHoursLogged[goal.id] = 0
        }
        
        // Sum logged hours for each goal
        for effort in efforts {
            if let currentValue = goalHoursLogged[effort.goalId] {
                goalHoursLogged[effort.goalId] = currentValue + effort.hours
            }
        }
        
        // Calculate weighted completion rate
        var totalWeightedCompletion: Double = 0
        var totalWeight: Double = 0
        
        for goal in sprint.goals {
            let target = goalTargetHours[goal.id] ?? 0
            let logged = goalHoursLogged[goal.id] ?? 0
            let completion = target > 0 ? min(logged / target, 1.0) : 0
            
            totalWeightedCompletion += completion * goal.weight
            totalWeight += goal.weight
        }
        
        return totalWeight > 0 ? totalWeightedCompletion / totalWeight : 0
    }
    
    // Get goal performance data for chart
    private func getGoalPerformance() -> [GoalPerformanceData] {
        var result: [GoalPerformanceData] = []
        let efforts = sprintStore.effortsForSprint(sprint)
        
        // Calculate days elapsed in sprint
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let daysElapsed = max(1, (calendar.dateComponents([.day], from: sprintStart, to: min(today, sprint.endDate)).day ?? 0) + 1)
        
        // Calculate logged hours vs target for each goal
        for goal in sprint.goals {
            let targetHours = goal.targetHours * Double(daysElapsed)
            let loggedHours = efforts
                .filter { $0.goalId == goal.id }
                .reduce(0) { $0 + $1.hours }
            
            let performance = targetHours > 0 ? loggedHours / targetHours : 0
            
            result.append(GoalPerformanceData(
                id: goal.id,
                title: goal.title,
                targetHours: targetHours,
                loggedHours: loggedHours,
                performance: performance
            ))
        }
        
        return result
    }
}

// Data structure for goal performance
struct GoalPerformanceData: Identifiable {
    var id: UUID
    var title: String
    var targetHours: Double
    var loggedHours: Double
    var performance: Double
}

// Progress stat card component
struct ProgressStatCard: View {
    let title: String
    let value: String
    let percentage: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(progressColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            ProgressBar(value: percentage)
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var progressColor: Color {
        if percentage < 0.4 {
            return .red
        } else if percentage < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

// Simple progress bar component
struct ProgressBar: View {
    let value: Double // 0.0 - 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                
                Rectangle()
                    .fill(progressColor)
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width))
                    .cornerRadius(5)
            }
        }
    }
    
    private var progressColor: Color {
        if value < 0.4 {
            return .red
        } else if value < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}
