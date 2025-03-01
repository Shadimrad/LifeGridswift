//
//  SprintStore.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import Foundation
import Combine

class SprintStore: ObservableObject {
    @Published var sprints: [Sprint] = []
    @Published var efforts: [Effort] = []
    
    // Initialize and load data
    init() {
        loadSprints()
        loadEfforts()
    }
    
    // MARK: - Persistence Methods
    
    func saveSprints() {
        DataPersistence.shared.saveSprints(sprints)
    }
    
    func loadSprints() {
        sprints = DataPersistence.shared.loadSprints()
    }
    
    func saveEfforts() {
        DataPersistence.shared.saveEfforts(efforts)
    }
    
    func loadEfforts() {
        efforts = DataPersistence.shared.loadEfforts()
    }
    
    // MARK: - Sprint Methods
    
    func addSprint(_ sprint: Sprint) {
        sprints.append(sprint)
        saveSprints()
    }
    
    func updateSprint(_ updatedSprint: Sprint) {
        if let index = sprints.firstIndex(where: { $0.id == updatedSprint.id }) {
            sprints[index] = updatedSprint
            saveSprints()
        }
    }
    
    func deleteSprint(_ sprint: Sprint) {
        // Also delete any efforts associated with this sprint's goals
        let goalIds = Set(sprint.goals.map { $0.id })
        efforts.removeAll { goalIds.contains($0.goalId) }
        
        // Remove the sprint
        sprints.removeAll { $0.id == sprint.id }
        
        // Save changes
        saveSprints()
        saveEfforts()
    }
    
    // MARK: - Effort Methods
    
    func addEffort(_ effort: Effort) {
        efforts.append(effort)
        saveEfforts()
    }
    
    func updateEffort(_ updatedEffort: Effort) {
        if let index = efforts.firstIndex(where: { $0.id == updatedEffort.id }) {
            efforts[index] = updatedEffort
            saveEfforts()
        }
    }
    
    func deleteEffort(_ effort: Effort) {
        efforts.removeAll { $0.id == effort.id }
        saveEfforts()
    }
    
    // Delete all efforts for a specific goal
    func deleteEffortsForGoal(goalId: UUID) {
        efforts.removeAll { $0.goalId == goalId }
        saveEfforts()
    }
    
    // MARK: - Query Methods
    
    // Get all efforts for a specific sprint
    func effortsForSprint(_ sprint: Sprint) -> [Effort] {
        let goalIds = Set(sprint.goals.map { $0.id })
        return efforts.filter { goalIds.contains($0.goalId) }
    }
    
    // Get all efforts for a specific date
    func effortsForDate(_ date: Date) -> [Effort] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return efforts.filter { effort in
            let effortDay = calendar.startOfDay(for: effort.date)
            return calendar.isDate(effortDay, inSameDayAs: targetDay)
        }
    }
    
    // Get goals from all sprints that match the goal ID
    func getGoalById(_ goalId: UUID) -> Goal? {
        for sprint in sprints {
            if let goal = sprint.goals.first(where: { $0.id == goalId }) {
                return goal
            }
        }
        return nil
    }
    
    // Find which sprint a goal belongs to
    func getSprintForGoal(_ goalId: UUID) -> Sprint? {
        return sprints.first { sprint in
            sprint.goals.contains(where: { $0.id == goalId })
        }
    }
    
    // Check if a date is within any sprint
    func isDateInAnySprint(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return sprints.contains { sprint in
            let sprintStart = calendar.startOfDay(for: sprint.startDate)
            let sprintEnd = calendar.startOfDay(for: sprint.endDate)
            return targetDay >= sprintStart && targetDay <= sprintEnd
        }
    }
    
    // MARK: - Data Generation for Charts and Visualizations
    
    // Generate day data for a date range
    func generateDayDataForRange(startDate: Date, endDate: Date) -> [DayData] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        // Calculate number of days in the range
        guard let dayCount = calendar.dateComponents([.day], from: startDay, to: endDay).day?.magnitude else {
            return []
        }
        
        var result: [DayData] = []
        
        // Create a day data entry for each day in the range
        for dayOffset in 0...dayCount {
            guard let currentDate = calendar.date(byAdding: .day, value: Int(dayOffset), to: startDay) else {
                continue
            }
            
            // Get all efforts for this day
            let dayEfforts = effortsForDate(currentDate)
            
            // If no efforts, add with nil score
            if dayEfforts.isEmpty {
                result.append(DayData(date: currentDate, score: nil))
                continue
            }
            
            // Calculate weighted score based on goals
            var dayScore = 0.0
            
            for effort in dayEfforts {
                if let goal = getGoalById(effort.goalId) {
                    let targetHours = goal.targetHours
                    let progress = min(effort.hours / targetHours, 1.0)
                    let weightedScore = progress * goal.weight
                    dayScore += weightedScore
                }
            }
            
            // Cap at 1.0 (100%)
            result.append(DayData(date: currentDate, score: min(1.0, dayScore)))
        }
        
        return result
    }
    
    // Generate stats for a specific time period
    func generateStatsForPeriod(days: Int) -> (avgScore: Double, completionRate: Double, streak: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return (0, 0, 0)
        }
        
        // Get day data
        let dayData = generateDayDataForRange(startDate: startDate, endDate: today)
        
        // Calculate average score
        let daysWithScores = dayData.filter { $0.score != nil }
        let avgScore = daysWithScores.isEmpty ? 0 : daysWithScores.reduce(0.0) { $0 + ($1.score ?? 0) } / Double(daysWithScores.count)
        
        // Calculate completion rate
        let completionRate = Double(daysWithScores.count) / Double(dayData.count)
        
        // Calculate current streak
        var streak = 0
        var currentDate = today
        
        while true {
            let dayData = generateDayDataForRange(startDate: currentDate, endDate: currentDate)
            
            guard let dayScore = dayData.first?.score, dayScore > 0.3 else {
                break
            }
            
            streak += 1
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            
            currentDate = previousDay
        }
        
        return (avgScore, completionRate, streak)
    }
}
