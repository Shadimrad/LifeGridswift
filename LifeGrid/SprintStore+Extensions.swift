//
//  SprintStore+Extensions.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//

import Foundation

extension SprintStore {
    // Find a sprint that contains a specific date
    func sprintForDate(_ date: Date) -> Sprint? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return sprints.first { sprint in
            let sprintStart = calendar.startOfDay(for: sprint.startDate)
            let sprintEnd = calendar.startOfDay(for: sprint.endDate)
            return targetDay >= sprintStart && targetDay <= sprintEnd
        }
    }
    
    // Get all sprints that overlap with a date range
    func sprintsForDateRange(startDate: Date, endDate: Date) -> [Sprint] {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: startDate)
        let rangeEnd = calendar.startOfDay(for: endDate)
        
        return sprints.filter { sprint in
            let sprintStart = calendar.startOfDay(for: sprint.startDate)
            let sprintEnd = calendar.startOfDay(for: sprint.endDate)
            
            // Sprint starts or ends within the range, or completely encompasses the range
            return (sprintStart <= rangeEnd && sprintEnd >= rangeStart)
        }
    }
    
    // Check if a specific day has any effort logged
    func hasEffortForDay(_ date: Date) -> Bool {
        let dayEfforts = effortsForDate(date)
        return !dayEfforts.isEmpty
    }
    
    // Get total hours logged for a day
    func totalHoursForDay(_ date: Date) -> Double {
        let dayEfforts = effortsForDate(date)
        return dayEfforts.reduce(0.0) { $0 + $1.hours }
    }
    
    // Calculate active sprint count
    func activeSprintCount() -> Int {
        let today = Date()
        return sprints.filter { sprint in
            today >= sprint.startDate && today <= sprint.endDate
        }.count
    }
    
    // Calculate sprint completion percentage
    func completionPercentage(for sprint: Sprint) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // If sprint hasn't started, return 0
        if today < calendar.startOfDay(for: sprint.startDate) {
            return 0
        }
        
        // If sprint is complete, return 100%
        if today > calendar.startOfDay(for: sprint.endDate) {
            return 1.0
        }
        
        // Calculate days elapsed vs total days
        let totalDays = calendar.dateComponents([.day], from: sprint.startDate, to: sprint.endDate).day ?? 1
        let elapsedDays = calendar.dateComponents([.day], from: sprint.startDate, to: today).day ?? 0
        
        return min(1.0, Double(elapsedDays) / Double(totalDays))
    }
}
