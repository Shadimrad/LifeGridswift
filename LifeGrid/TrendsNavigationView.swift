//
//  TrendsNavigationView.swift
//  LifeGrid
//
//  Created on 2/28/25.
//

import SwiftUI

// This view serves as a centralized access point for all visualization views
struct TrendsNavigationView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var selectedTab: TrendTab = .overview
    
    enum TrendTab: String, CaseIterable {
        case overview = "Overview"
        case performance = "Performance"
        case comparison = "Comparison"
        case detailed = "Detailed"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .performance: return "chart.pie.fill"
            case .comparison: return "chart.xyaxis.line"
            case .detailed: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(TrendTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 24))
                                Text(tab.rawValue)
                                    .font(.caption)
                            }
                            .frame(width: 90, height: 70)
                            .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                            .foregroundColor(selectedTab == tab ? .blue : .primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTab == tab ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            
            // Divider
            Divider()
                .padding(.bottom, 8)
            
            // Content based on selected tab
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .overview:
                        TrendsView()
                            .environmentObject(sprintStore)
                    case .performance:
                        PerformanceView()
                            .environmentObject(sprintStore)
                    case .comparison:
                        ComparisonView()
                            .environmentObject(sprintStore)
                    case .detailed:
                        EnhancedVisualizationsView()
                            .environmentObject(sprintStore)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Analytics & Trends")
        .background(Color(.systemGroupedBackground))
    }
}

// Performance View - focuses on goal performance
struct PerformanceView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedSprint: Sprint? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Time range and sprint selectors
            HStack {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Sprint picker
                Picker("Sprint", selection: $selectedSprint) {
                    Text("All Sprints").tag(nil as Sprint?)
                    ForEach(sprintStore.sprints) { sprint in
                        Text(sprint.name).tag(sprint as Sprint?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
//            // Goal performance chart
//            if #available(iOS 16.0, *) {
//                // For iOS 16 and above, use the goal performance chart from EnhancedVisualizationsView
//                GoalPerformanceSection(sprintStore: sprintStore, selectedSprint: selectedSprint, timeRange: selectedTimeRange)
//            } else {
//                // Fallback for iOS 15
//                SimplifiedGoalPerformanceView(sprintStore: sprintStore, selectedSprint: selectedSprint, selectedTimeRange: selectedTimeRange)
//            }
//            
//            // Activity distribution
//            if #available(iOS 16.0, *) {
//                ActivityDistributionSection(sprintStore: sprintStore, selectedSprint: selectedSprint, timeRange: selectedTimeRange)
//            } else {
//                Text("Enhanced activity distribution requires iOS 16+")
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding()
//                    .background(Color(.systemBackground))
//                    .cornerRadius(12)
//                    .padding(.horizontal)
//            }
            
            // Trend analysis
            TrendAnalysisView()
                .environmentObject(sprintStore)
                .padding(.horizontal)
        }
    }
}

// Simplified Goal Performance View for iOS 15
struct SimplifiedGoalPerformanceView: View {
    let sprintStore: SprintStore
    let selectedSprint: Sprint?
    let selectedTimeRange: TimeRange
    
    // Get goal performance data
    private var goalPerformanceData: [GoalPerformance] {
        // Use the function from TrendsView to calculate performance
        // Just reference the internal function logic here
        
        // Implementation would calculate goal performance based on
        // selected sprint and time range
        
        return []  // Placeholder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Performance")
                .font(.headline)
                .padding(.horizontal)
            
            if goalPerformanceData.isEmpty {
                Text("No goal data available for the selected period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(goalPerformanceData) { goal in
                    HStack {
                        Text(goal.goalTitle)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        // Simple progress bar
                        ProgressBar(value: goal.performance)
                            .frame(width: 150, height: 12)
                        
                        Text("\(Int(goal.performance * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Goal Performance Section from EnhancedVisualizationsView
@available(iOS 16.0, *)
struct GoalPerformanceSection: View {
    let sprintStore: SprintStore
    let selectedSprint: Sprint?
    let timeRange: TimeRange
    
    // Calculate date range from timeRange
    private var dateRange: (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        var startDate: Date
        switch timeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: today) ?? today
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        }
        
        return (startDate, today)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Performance")
                .font(.headline)
            
            // This would use the appropriate chart components from EnhancedVisualizationsView
            Text("Performance chart would go here")
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Activity Distribution Section from EnhancedVisualizationsView
@available(iOS 16.0, *)
struct ActivityDistributionSection: View {
    let sprintStore: SprintStore
    let selectedSprint: Sprint?
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Distribution")
                .font(.headline)
            
            // This would use the appropriate chart components from EnhancedVisualizationsView
            Text("Activity distribution chart would go here")
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Comparison View - allows comparing different time periods
struct ComparisonView: View {
    @EnvironmentObject var sprintStore: SprintStore
    
    var body: some View {
        VStack(spacing: 20) {
//            if #available(iOS 16.0, *) {
//                // Weekly comparison chart from EnhancedVisualizationsView
//                WeeklyComparisonSection(sprintStore: sprintStore)
//            } else {
//                Text("Weekly comparison requires iOS 16+")
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding()
//                    .background(Color(.systemBackground))
//                    .cornerRadius(12)
//                    .padding(.horizontal)
//            }
            
            // Sprint comparison section
            SprintComparisonSection(sprintStore: sprintStore)
        }
    }
}

// Weekly Comparison Section
@available(iOS 16.0, *)
struct WeeklyComparisonSection: View {
    let sprintStore: SprintStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Comparison")
                .font(.headline)
            
            // This would use the weekly comparison chart from EnhancedVisualizationsView
            Text("Weekly comparison chart would go here")
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Sprint Comparison Section
struct SprintComparisonSection: View {
    let sprintStore: SprintStore
    @State private var selectedSprints: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sprint Comparison")
                .font(.headline)
            
            if sprintStore.sprints.count < 2 {
                Text("At least two sprints are needed for comparison")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Sprint selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sprintStore.sprints) { sprint in
                            Button {
                                toggleSprintSelection(sprint.id)
                            } label: {
                                Text(sprint.name)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedSprints.contains(sprint.id) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedSprints.contains(sprint.id) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Comparison view
                if selectedSprints.count >= 2 {
                    sprintComparisonData
                } else {
                    Text("Select at least two sprints to compare")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Toggle sprint selection
    private func toggleSprintSelection(_ id: UUID) {
        if selectedSprints.contains(id) {
            selectedSprints.remove(id)
        } else {
            // Limit to 3 sprints for comparison
            if selectedSprints.count < 3 {
                selectedSprints.insert(id)
            }
        }
    }
    
    // Sprint comparison data
    private var sprintComparisonData: some View {
        VStack(spacing: 12) {
            // Selected sprints comparison
            VStack(spacing: 16) {
                ForEach(sprintStore.sprints.filter { selectedSprints.contains($0.id) }) { sprint in
                    sprintSummaryRow(for: sprint)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // Sprint summary row
    private func sprintSummaryRow(for sprint: Sprint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sprint.name)
                .font(.headline)
            
            Text("\(sprint.startDate, style: .date) - \(sprint.endDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Calculate stats for this sprint
            let stats = calculateSprintStats(sprint)
            
            // Stats grid
            HStack(spacing: 16) {
                TrendStatItem(title: "Avg. Score", value: "\(Int(stats.averageScore * 100))%")
                TrendStatItem(title: "Completion", value: "\(Int(stats.completionRate * 100))%")
                TrendStatItem(title: "Daily Hours", value: String(format: "%.1f", stats.averageHours))
            }
            
            // Goal achievement
            Text("Goal Achievement:")
                .font(.subheadline)
                .padding(.top, 4)
            
            ForEach(sprint.goals) { goal in
                let achievement = calculateGoalAchievement(goal: goal, sprint: sprint)
                HStack {
                    Text(goal.title)
                        .font(.caption)
                    
                    Spacer()
                    
                    ProgressBar(value: achievement)
                        .frame(width: 100, height: 6)
                    
                    Text("\(Int(achievement * 100))%")
                        .font(.caption)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Calculate stats for a sprint
    private func calculateSprintStats(_ sprint: Sprint) -> (averageScore: Double, completionRate: Double, averageHours: Double) {
        // Get efforts for this sprint
        let sprintEfforts = sprintStore.effortsForSprint(sprint)
        
        // Default values
        var averageScore = 0.0
        var completionRate = 0.0
        var averageHours = 0.0
        
        // Calculate stats if there are efforts
        if !sprintEfforts.isEmpty {
            // Group efforts by date
            let calendar = Calendar.current
            var effortsByDate: [Date: [Effort]] = [:]
            
            for effort in sprintEfforts {
                let dayDate = calendar.startOfDay(for: effort.date)
                if effortsByDate[dayDate] == nil {
                    effortsByDate[dayDate] = [effort]
                } else {
                    effortsByDate[dayDate]?.append(effort)
                }
            }
            
            // Calculate daily scores
            var dailyScores: [Double] = []
            
            for (_, dayEfforts) in effortsByDate {
                var dayScore = 0.0
                
                for effort in dayEfforts {
                    if let goal = sprint.goals.first(where: { $0.id == effort.goalId }) {
                        let dailyTarget = goal.targetHours
                        let progress = min(effort.hours / dailyTarget, 1.0)
                        let weightedScore = progress * goal.weight
                        dayScore += weightedScore
                    }
                }
                
                dailyScores.append(min(1.0, dayScore))
            }
            
            // Calculate average score
            averageScore = dailyScores.isEmpty ? 0 : dailyScores.reduce(0, +) / Double(dailyScores.count)
            
            // Calculate completion rate
            let totalDays = calendar.dateComponents([.day], from: sprint.startDate, to: min(Date(), sprint.endDate)).day ?? 1
            completionRate = Double(effortsByDate.count) / Double(totalDays)
            
            // Calculate average hours per day
            let totalHours = sprintEfforts.reduce(0.0) { $0 + $1.hours }
            averageHours = totalHours / Double(effortsByDate.count)
        }
        
        return (averageScore, completionRate, averageHours)
    }
    
    // Calculate goal achievement percentage
    private func calculateGoalAchievement(goal: Goal, sprint: Sprint) -> Double {
        // Get efforts for this goal
        let goalEfforts = sprintStore.efforts.filter { $0.goalId == goal.id }
        
        // If no efforts, return 0
        if goalEfforts.isEmpty {
            return 0
        }
        
        // Calculate total logged hours
        let totalLoggedHours = goalEfforts.reduce(0.0) { $0 + $1.hours }
        
        // Calculate expected target hours
        let calendar = Calendar.current
        let daysInSprint = calendar.dateComponents([.day], from: sprint.startDate, to: sprint.endDate).day ?? 1
        let targetHours = goal.targetHours * Double(daysInSprint)
        
        // Calculate achievement percentage (capped at 100%)
        return min(totalLoggedHours / targetHours, 1.0)
    }
}

// Simple stat item component for trends
struct TrendStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
struct TrendsNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy instance of SprintStore.
        // Optionally, populate it with sample sprints, efforts, goals, etc.
        let sprintStore = SprintStore()
        
        return NavigationView {
            TrendsNavigationView()
                .environmentObject(sprintStore)
        }
        // You can also preview in both light and dark modes:
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        // Uncomment the following to preview dark mode as well:
        // NavigationView {
        //     TrendsNavigationView()
        //         .environmentObject(sprintStore)
        // }
        // .preferredColorScheme(.dark)
        // .previewDisplayName("Dark Mode")
    }
}
#endif
