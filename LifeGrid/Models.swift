//
//  Models.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

// MARK: - Data Models

/// Represents tracked data for a day.
struct DayData: Identifiable, Codable, Equatable {
    var id = UUID()
    let date: Date
    let score: Double? // nil if no data logged
    
    init(date: Date, score: Double? = nil) {
        self.date = date
        self.score = score
    }
}

// Structure to hold data for a year
struct YearData: Identifiable, Codable {
    var id = UUID()
    var year: Int
    var startDate: Date
    var endDate: Date
    var days: [DayData]
    
    // Convenience computed properties
    var title: String {
        String(year)
    }
    
    var averageScore: Double? {
        let daysWithScores = days.filter { $0.score != nil }
        guard !daysWithScores.isEmpty else {
            return nil
        }
        
        let totalScore = daysWithScores.reduce(0.0) { $0 + ($1.score ?? 0) }
        return totalScore / Double(daysWithScores.count)
    }
}

// Structure to hold data for a month
struct MonthData: Identifiable, Codable {
    var id = UUID()
    var year: Int
    var month: Int
    var title: String
    var days: [DayData]
    
    // Convenience computed property for average score
    var averageScore: Double? {
        let daysWithScores = days.filter { $0.score != nil }
        guard !daysWithScores.isEmpty else {
            return nil
        }
        
        let totalScore = daysWithScores.reduce(0.0) { $0 + ($1.score ?? 0) }
        return totalScore / Double(daysWithScores.count)
    }
}

// Additional extension to add monthly grouping of days
extension YearData {
    // Group days by month
    func groupByMonths() -> [MonthData] {
        let calendar = Calendar.current
        var monthGroups: [Int: [DayData]] = [:]
        
        // Group days by month
        for day in days {
            let month = calendar.component(.month, from: day.date)
            if monthGroups[month] == nil {
                monthGroups[month] = [day]
            } else {
                monthGroups[month]?.append(day)
            }
        }
        
        // Convert to MonthData objects
        return monthGroups.keys.sorted().map { month in
            let monthDays = monthGroups[month] ?? []
            
            // Get month name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            let monthName = dateFormatter.monthSymbols[month - 1]
            
            return MonthData(
                year: year,
                month: month,
                title: monthName,
                days: monthDays
            )
        }
    }
}

struct Sprint: Identifiable, Hashable, Codable{
    var id = UUID()
    var name: String
    var startDate: Date
    var endDate: Date
    var goals: [Goal]
    
    //  to make Sprint Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // to make Sprint Equatable (required for Hashable)
    static func == (lhs: Sprint, rhs: Sprint) -> Bool {
        lhs.id == rhs.id
    }
    
    // This method calculates the daily scores for this sprint.
    func dailyScores(for efforts: [Effort]) -> [Double] {
        let calendar = Calendar.current
        guard let daysCount = calendar.dateComponents([.day], from: startDate, to: endDate).day.map({ $0 + 1 }) else {
            return []
        }
        var dailyScores = Array(repeating: 0.0, count: daysCount)
        for effort in efforts {
            guard let dayIndex = calendar.dateComponents([.day], from: startDate, to: effort.date).day,
                  dayIndex >= 0, dayIndex < daysCount else { continue }
            guard let goal = goals.first(where: { $0.id == effort.goalId }) else { continue }
            let progress = min(effort.hours / goal.targetHours, 1.0)
            let score = progress * goal.weight
            dailyScores[dayIndex] += score
        }
        return dailyScores
    }
}

struct Goal: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var targetHours: Double
    var weight: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }
}

struct Effort: Identifiable, Codable {
    var id = UUID()
    var goalId: UUID       // Reference to which goal this effort is for.
    var date: Date         // The day this effort was logged.
    var hours: Double      // How many hours were logged.
}

enum TrendDirection {
    case up
    case down
    case neutral
    
    var icon: String {
        switch self {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .neutral:
            return "arrow.forward"
        }
    }
    
    var color: Color {
        switch self {
        case .up:
            return .green
        case .down:
            return .red
        case .neutral:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .up:
            return "Improving"
        case .down:
            return "Declining"
        case .neutral:
            return "Stable"
        }
    }
}
