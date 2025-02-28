//
//  Models.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//
import SwiftUI
// MARK: - 2) Models

/// Represents tracked data for a day.
/// (You can later expand this to use your actual Effort/Sprint logic.)
struct DayData: Identifiable, Codable, Equatable {
    var id = UUID()
    let date: Date
    let score: Double? // nil if no data logged
    
    init(date: Date, score: Double? = nil) {
        self.date = date
        self.score = score
    }
}

struct Sprint: Identifiable, Codable {
    var id = UUID()
    var name: String
    var startDate: Date
    var endDate: Date
    var goals: [Goal]
    
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

struct Goal: Identifiable, Codable {
    var id = UUID()
    var title: String
    var targetHours: Double  // e.g., 2 hours per day
    var weight: Double       // e.g., 0.4 for 40% of the total score (or any scale you decide)
}

struct Effort: Identifiable, Codable {
    var id = UUID()
    var goalId: UUID       // Reference to which goal this effort is for.
    var date: Date         // The day this effort was logged.
    var hours: Double      // How many hours were logged.
}

class SprintStore: ObservableObject {
    @Published var sprints: [Sprint] = []
}
