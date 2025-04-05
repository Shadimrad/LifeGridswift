//
//  SprintProgressCalculator.swift
//  LifeGrid
//
//  Created on April 5, 2025.
//

import SwiftUI

// Sprint progress calculation utility
struct SprintProgressCalculator {
    
    // Calculate overall progress percentage of a sprint
    static func calculateSprintProgress(sprint: Sprint, currentDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: sprint.startDate)
        let endDate = calendar.startOfDay(for: sprint.endDate)
        let today = calendar.startOfDay(for: currentDate)
        
        // If sprint hasn't started, progress is 0
        if today < startDate {
            return 0.0
        }
        
        // If sprint is finished, progress is 100%
        if today > endDate {
            return 1.0
        }
        
        // Calculate elapsed days / total days
        guard let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day,
              let elapsedDays = calendar.dateComponents([.day], from: startDate, to: today).day else {
            return 0.0
        }
        
        return totalDays > 0 ? min(Double(elapsedDays) / Double(totalDays), 1.0) : 0.0
    }
    
    // Calculate detailed sprint statistics
    static func calculateSprintStats(sprint: Sprint, currentDate: Date = Date()) -> SprintStatistics {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: currentDate)
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let sprintEnd = calendar.startOfDay(for: sprint.endDate)
        
        // Calculate total days in sprint
        let totalDays = calendar.dateComponents([.day], from: sprintStart, to: sprintEnd).day ?? 0
        
        // Calculate days elapsed so far (capped at total days)
        let elapsedDays = min(
            calendar.dateComponents([.day], from: sprintStart, to: now).day ?? 0,
            totalDays
        )
        
        // Calculate days remaining
        let remainingDays = max(0, totalDays - elapsedDays)
        
        // Calculate percentage completed
        let percentCompleted = totalDays > 0 ? (Double(elapsedDays) / Double(totalDays)) : 0
        
        // Calculate weeks passed and remaining
        let weeksPassed = elapsedDays / 7
        let weeksRemaining = remainingDays / 7
        
        return SprintStatistics(
            daysPassed: elapsedDays,
            daysRemaining: remainingDays,
            totalDays: totalDays,
            weeksPassed: weeksPassed,
            weeksRemaining: weeksRemaining,
            percentCompleted: percentCompleted,
            startDate: sprintStart,
            endDate: sprintEnd
        )
    }
    
    // Calculate stats for the longest sprint in the store
    static func calculateLongestSprintStats(sprintStore: SprintStore, currentDate: Date = Date()) -> SprintStatistics? {
        guard let longestSprint = findLongestSprint(in: sprintStore) else {
            return nil
        }
        
        return calculateSprintStats(sprint: longestSprint, currentDate: currentDate)
    }
    
    // Find the longest sprint in the store
    static func findLongestSprint(in sprintStore: SprintStore) -> Sprint? {
        return sprintStore.sprints.sorted { sprint1, sprint2 in
            let calendar = Calendar.current
            let duration1 = calendar.dateComponents([.day], from: sprint1.startDate, to: sprint1.endDate).day ?? 0
            let duration2 = calendar.dateComponents([.day], from: sprint2.startDate, to: sprint2.endDate).day ?? 0
            return duration1 > duration2
        }.first
    }
}

// Sprint statistics data structure
struct SprintStatistics {
    let daysPassed: Int
    let daysRemaining: Int
    let totalDays: Int
    let weeksPassed: Int
    let weeksRemaining: Int
    let percentCompleted: Double
    let startDate: Date
    let endDate: Date
    
    // Computed properties for formatted values
    var formattedPercentCompleted: String {
        return String(format: "%.1f%%", percentCompleted * 100)
    }
    
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
    
    var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: endDate)
    }
}

// Sprint statistics view component
struct SprintStatsView: View {
    let stats: SprintStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sprint Progress")
                .font(.headline)
            
            // Progress bar
            ProgressView(value: stats.percentCompleted)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(stats.formattedPercentCompleted)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatItem(title: "Days Passed", value: "\(stats.daysPassed)")
                StatItem(title: "Days Remaining", value: "\(stats.daysRemaining)")
                StatItem(title: "Weeks Passed", value: "\(stats.weeksPassed)")
                StatItem(title: "Weeks Remaining", value: "\(stats.weeksRemaining)")
                StatItem(title: "Total Days", value: "\(stats.totalDays)")
                StatItem(title: "Total Weeks", value: "\(stats.totalDays / 7)")
            }
            
            // Date range information
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Start Date:")
                    Spacer()
                    Text(stats.formattedStartDate)
                }
                
                HStack {
                    Text("End Date:")
                    Spacer()
                    Text(stats.formattedEndDate)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// Stat item component
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
