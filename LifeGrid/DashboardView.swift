//
//  DashboardView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//

import SwiftUI

// This view brings together all our components in a dashboard
struct DashboardView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var selectedSection: DashboardSection = .lifeProgress
    
    enum DashboardSection: String, CaseIterable, Identifiable {
        case lifeProgress = "Life Progress"
        case currentSprints = "Active Sprints"
        case trends = "Trends & Analytics"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .lifeProgress: return "calendar"
            case .currentSprints: return "list.bullet.clipboard"
            case .trends: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(DashboardSection.allCases) { section in
                                Button {
                                    withAnimation {
                                        selectedSection = section
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: section.icon)
                                            .font(.system(size: 24))
                                        Text(section.rawValue)
                                            .font(.caption)
                                    }
                                    .frame(width: 100, height: 80)
                                    .background(selectedSection == section ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                                    .foregroundColor(selectedSection == section ? .blue : .primary)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedSection == section ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
                    // Selected section content
                    Group {
                        switch selectedSection {
                        case .lifeProgress:
                            lifeProgressSection
                        case .currentSprints:
                            activeSprints
                        case .trends:
                            trendsPreview
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }
    
    // Life progress section
    private var lifeProgressSection: some View {
        VStack(spacing: 16) {
            // Life stats view
            let lifeStats = LifeProgressCalculator.calculateLifeStats(
                currentAge: userSettings.currentAge,
                targetAge: userSettings.targetAge
            )
            
            LifeStatsView(stats: lifeStats)
                .padding(.horizontal)
            
            // Grid preview
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Life Grid Preview")
                        .font(.headline)
                    
                    Spacer()
                    
                    NavigationLink(destination: LifetimeGridView()) {
                        Text("View Full Grid")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Create a mini grid visualization
                let weeksPerRow = 52 // Weeks in a year
                let totalWeeks = lifeStats.yearsRemaining * 52 + lifeStats.weeksLived
                let rowsToShow = min(5, totalWeeks / weeksPerRow) // Show 5 years max
                
                VStack(spacing: 2) {
                    ForEach(0..<rowsToShow, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<weeksPerRow, id: \.self) { col in
                                let weekIndex = row * weeksPerRow + col
                                Rectangle()
                                    .fill(weekIndex < lifeStats.weeksLived ? Color.green.opacity(0.7) : Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                    .cornerRadius(1)
                            }
                        }
                    }
                }
                
                Text("Each box represents one week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // Active sprints section
    private var activeSprints: some View {
        VStack(spacing: 16) {
            // Current active sprints
            let activeSprintsList = getActiveSprintsList()
            
            if activeSprintsList.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Active Sprints")
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
            } else {
                // List of active sprints
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active Sprints")
                            .font(.headline)
                        
                        Spacer()
                        
                        NavigationLink(destination: SprintsView()) {
                            Text("Manage")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ForEach(activeSprintsList) { sprint in
                        NavigationLink(destination: SprintDetailView(sprint: sprint)) {
                            sprintCardView(for: sprint)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                
                // Quick log effort button
                if let currentSprint = activeSprintsList.first {
                    NavigationLink(destination: DatePickerEffortLoggingView(sprint: currentSprint)) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Effort for Today")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // Sprint card view
    private func sprintCardView(for sprint: Sprint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sprint.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let progress = calculateSprintProgress(sprint)
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Date range
            Text("\(sprint.startDate, style: .date) - \(sprint.endDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Progress bar
            ProgressView(value: calculateSprintProgress(sprint))
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 6)
                .padding(.vertical, 4)
            
            // Goals preview
            if !sprint.goals.isEmpty {
                Text("Goals: \(sprint.goals.map { $0.title }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Trends preview section
    private var trendsPreview: some View {
        VStack(spacing: 16) {
            // Statistics cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statsCard(
                    title: "Last 7 Days",
                    value: calculateAverageScoreForPeriod(days: 7),
                    trend: calculateTrendForPeriod(days: 7),
                    valueFormat: "%.0f%%"
                )
                
                statsCard(
                    title: "Current Streak",
                    value: Double(calculateCurrentStreak()),
                    trend: nil,
                    valueFormat: "%.0f days"
                )
                
                statsCard(
                    title: "Weekly Hours",
                    value: calculateAverageHoursForPeriod(days: 7),
                    trend: calculateHoursTrendForPeriod(days: 7),
                    valueFormat: "%.1f hrs"
                )
                
                statsCard(
                    title: "Completion",
                    value: calculateCompletionRate() * 100,
                    trend: nil,
                    valueFormat: "%.0f%%"
                )
            }
            .padding(.horizontal)
            
            // Trends chart preview - it's just a navigation link
            NavigationLink(destination: EnhancedVisualizationsView()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trend Analysis")
                        .font(.headline)
                    
                    // Just a preview placeholder
                    if #available(iOS 16.0, *) {
                        // This would be a real chart in iOS 16+
                        // For now, just show a placeholder image
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 30)
                    } else {
                        // Fallback on earlier versions
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 30)
                    }
                    
                    Text("Tap to view detailed analytics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }
    
    private func statsCard(title: String, value: Double, trend: TrendDirection?, valueFormat: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(String(format: valueFormat, value))
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .foregroundColor(trend.color)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // Helper functions for stats
    
    // Get active sprints
    private func getActiveSprintsList() -> [Sprint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sprintStore.sprints
            .filter { sprint in
                let startDate = calendar.startOfDay(for: sprint.startDate)
                let endDate = calendar.startOfDay(for: sprint.endDate)
                return startDate <= today && endDate >= today
            }
            .sorted { $0.startDate > $1.startDate }
    }
    
    // Calculate sprint progress
    private func calculateSprintProgress(_ sprint: Sprint) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: sprint.startDate)
        let endDate = calendar.startOfDay(for: sprint.endDate)
        
        guard startDate <= today else { return 0 }
        guard endDate >= today else { return 1 }
        
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let daysElapsed = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        
        return Double(daysElapsed) / Double(totalDays)
    }
    
    // Calculate average score for period
    private func calculateAverageScoreForPeriod(days: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return 0
        }
        
        // Get day data
        let dayData = sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        
        // Calculate average
        let daysWithScores = dayData.filter { $0.score != nil }
        guard !daysWithScores.isEmpty else { return 0 }
        
        let totalScore = daysWithScores.reduce(0.0) { $0 + ($1.score ?? 0) }
        return (totalScore / Double(daysWithScores.count)) * 100 // Return as percentage
    }
    
    // Calculate trend
    private func calculateTrendForPeriod(days: Int) -> TrendDirection? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -(days * 2), to: today),
              let midPoint = calendar.date(byAdding: .day, value: days, to: startDate) else {
            return nil
        }
        
        // First period
        let firstPeriodData = sprintStore.generateDayDataForRange(startDate: startDate, endDate: midPoint)
        let firstPeriodScores = firstPeriodData.filter { $0.score != nil }
        
        // Second period
        let secondPeriodData = sprintStore.generateDayDataForRange(startDate: midPoint, endDate: today)
        let secondPeriodScores = secondPeriodData.filter { $0.score != nil }
        
        // Calculate averages
        guard !firstPeriodScores.isEmpty, !secondPeriodScores.isEmpty else {
            return nil
        }
        
        let firstAvg = firstPeriodScores.reduce(0.0) { $0 + ($1.score ?? 0) } / Double(firstPeriodScores.count)
        let secondAvg = secondPeriodScores.reduce(0.0) { $0 + ($1.score ?? 0) } / Double(secondPeriodScores.count)
        
        // Determine trend
        if secondAvg > firstAvg * 1.05 {
            return .up
        } else if secondAvg < firstAvg * 0.95 {
            return .down
        } else {
            return .neutral
        }
    }
    
    // Calculate current streak
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        while true {
            let dayData = sprintStore.generateDayDataForRange(startDate: currentDate, endDate: currentDate)
            
            guard let dayScore = dayData.first?.score, dayScore > 0.3 else {
                break
            }
            
            streak += 1
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            
            currentDate = previousDay
        }
        
        return streak
    }
    
    // Calculate average hours for period
    private func calculateAverageHoursForPeriod(days: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return 0
        }
        
        // Filter efforts for date range
        let filteredEfforts = sprintStore.efforts.filter { effort in
            let effortDate = calendar.startOfDay(for: effort.date)
            return effortDate >= startDate && effortDate <= today
        }
        
        // Calculate total hours
        let totalHours = filteredEfforts.reduce(0.0) { $0 + $1.hours }
        
        // Calculate average hours per day
        return totalHours / Double(days)
    }
    
    // Calculate hours trend
    private func calculateHoursTrendForPeriod(days: Int) -> TrendDirection? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -(days * 2), to: today),
              let midPoint = calendar.date(byAdding: .day, value: days, to: startDate) else {
            return nil
        }
        
        // Filter efforts for first period
        let firstPeriodEfforts = sprintStore.efforts.filter { effort in
            let effortDate = calendar.startOfDay(for: effort.date)
            return effortDate >= startDate && effortDate < midPoint
        }
        
        // Filter efforts for second period
        let secondPeriodEfforts = sprintStore.efforts.filter { effort in
            let effortDate = calendar.startOfDay(for: effort.date)
            return effortDate >= midPoint && effortDate <= today
        }
        
        // Calculate totals
        let firstTotalHours = firstPeriodEfforts.reduce(0.0) { $0 + $1.hours }
        let secondTotalHours = secondPeriodEfforts.reduce(0.0) { $0 + $1.hours }
        
        // Determine trend
        if secondTotalHours > firstTotalHours * 1.05 {
            return .up
        } else if secondTotalHours < firstTotalHours * 0.95 {
            return .down
        } else {
            return .neutral
        }
    }
    
    // Calculate completion rate
    private func calculateCompletionRate() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let past30Days = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        // Get day data
        let dayData = sprintStore.generateDayDataForRange(startDate: past30Days, endDate: today)
        
        // Count days with data
        let daysWithData = dayData.filter { $0.score != nil }
        
        return Double(daysWithData.count) / Double(max(1, dayData.count))
    }
    

}
