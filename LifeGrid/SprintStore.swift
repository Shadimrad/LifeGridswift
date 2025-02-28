//
//  SprintStore.swift
//  LifeGrid
//
//  Created on 2/27/25.
//

import SwiftUI
import Combine

// Main store for sprints and efforts
class SprintStore: ObservableObject {
    @Published var sprints: [Sprint] = [] {
        didSet {
            DataPersistence.shared.saveSprints(sprints)
        }
    }
    
    @Published var efforts: [Effort] = [] {
        didSet {
            DataPersistence.shared.saveEfforts(efforts)
        }
    }
    
    init() {
        // Load saved data
        self.sprints = DataPersistence.shared.loadSprints()
        self.efforts = DataPersistence.shared.loadEfforts()
    }
    
    // Add a new effort
    func addEffort(_ effort: Effort) {
        efforts.append(effort)
    }
    
    // Get efforts for a specific date
    func effortsForDate(_ date: Date) -> [Effort] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return efforts.filter { effort in
            let effortDay = calendar.startOfDay(for: effort.date)
            return calendar.isDate(effortDay, inSameDayAs: targetDay)
        }
    }
    
    // Get efforts for a specific sprint
    func effortsForSprint(_ sprint: Sprint) -> [Effort] {
        let calendar = Calendar.current
        let sprintStart = calendar.startOfDay(for: sprint.startDate)
        let sprintEnd = calendar.startOfDay(for: sprint.endDate)
        
        return efforts.filter { effort in
            let effortDay = calendar.startOfDay(for: effort.date)
            return effortDay >= sprintStart && effortDay <= sprintEnd
        }
    }
    
    // Get a sprint that contains a specific date
    func sprintForDate(_ date: Date) -> Sprint? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return sprints.first { sprint in
            let sprintStart = calendar.startOfDay(for: sprint.startDate)
            let sprintEnd = calendar.startOfDay(for: sprint.endDate)
            return targetDay >= sprintStart && targetDay <= sprintEnd
        }
    }
    
    // Generate day data for a specific date range
    func generateDayDataForRange(startDate: Date, endDate: Date) -> [DayData] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        guard let daysCount = calendar.dateComponents([.day], from: startDay, to: endDay).day.map({ $0 + 1 }) else {
            return []
        }
        
        var dayDataArray: [DayData] = []
        
        for i in 0..<daysCount {
            if let currentDate = calendar.date(byAdding: .day, value: i, to: startDay) {
                // Find if this day is part of any sprint
                if let sprint = sprintForDate(currentDate) {
                    let sprintEfforts = effortsForSprint(sprint)
                    let scores = sprint.dailyScores(for: sprintEfforts)
                    
                    // Find the day index in the sprint
                    if let dayIndex = calendar.dateComponents([.day], from: sprint.startDate, to: currentDate).day,
                       dayIndex >= 0 && dayIndex < scores.count {
                        // Get the score for this day
                        let score = scores[dayIndex]
                        dayDataArray.append(DayData(date: currentDate, score: score))
                    } else {
                        dayDataArray.append(DayData(date: currentDate, score: nil))
                    }
                } else {
                    // Not part of any sprint, add with nil score
                    dayDataArray.append(DayData(date: currentDate, score: nil))
                }
            }
        }
        
        return dayDataArray
    }
}

// A special class to manage lifetime grid data based on user settings
class LifetimeGridStore: ObservableObject {
    @Published var lifetimeData: [YearData] = []
    
    // Reference to our main data stores
    var userSettings: UserSettings
    var sprintStore: SprintStore
    
    private var cancellables = Set<AnyCancellable>()
    
    init(userSettings: UserSettings, sprintStore: SprintStore) {
        self.userSettings = userSettings
        self.sprintStore = sprintStore
        
        // Generate the lifetime data grid
        generateLifetimeData()
        
        // Set up subscriptions to update when underlying data changes
        setupSubscriptions()
    }
    
    // Set up subscriptions to update the grid when data changes
    private func setupSubscriptions() {
        // Update when user settings change
        userSettings.$currentAge
            .combineLatest(userSettings.$targetAge)
            .sink { [weak self] _, _ in
                self?.generateLifetimeData()
            }
            .store(in: &cancellables)
        
        // Update when sprints or efforts change
        sprintStore.$sprints
            .combineLatest(sprintStore.$efforts)
            .sink { [weak self] _, _ in
                self?.generateLifetimeData()
            }
            .store(in: &cancellables)
    }
    
    // Generate the lifetime grid data based on user settings
    func generateLifetimeData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate start date based on current age
        var dateComponents = DateComponents()
        dateComponents.year = -userSettings.currentAge
        let startDate = calendar.date(byAdding: dateComponents, to: today) ?? today
        
        // Calculate end date based on target age
        let yearsLeft = userSettings.targetAge - userSettings.currentAge
        dateComponents.year = yearsLeft
        let endDate = calendar.date(byAdding: dateComponents, to: today) ?? today
        
        // Initialize empty year data
        var years: [YearData] = []
        
        // Iterate through each year
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        
        var currentYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        
        while currentYear <= endYear {
            // Create year start and end dates
            var startComponents = DateComponents()
            startComponents.year = currentYear
            startComponents.month = 1
            startComponents.day = 1
            let yearStart = calendar.date(from: startComponents)!
            
            var endComponents = DateComponents()
            endComponents.year = currentYear
            endComponents.month = 12
            endComponents.day = 31
            let yearEnd = calendar.date(from: endComponents)!
            
            // Skip years before start date or after end date
            if yearEnd < startDate || yearStart > endDate {
                currentYear += 1
                continue
            }
            
            // Adjust start/end for partial years
            let adjustedStart = yearStart < startDate ? startDate : yearStart
            let adjustedEnd = yearEnd > endDate ? endDate : yearEnd
            
            // Get days for this year
            let days = generateDaysForRange(adjustedStart, adjustedEnd)
            
            // Create year data
            let yearData = YearData(
                year: currentYear,
                startDate: adjustedStart,
                endDate: adjustedEnd,
                days: days
            )
            
            years.append(yearData)
            currentYear += 1
        }
        
        self.lifetimeData = years
    }
    
    // Generate days for a date range
    private func generateDaysForRange(_ startDate: Date, _ endDate: Date) -> [DayData] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        guard let daysCount = calendar.dateComponents([.day], from: startDay, to: endDay).day.map({ $0 + 1 }) else {
            return []
        }
        
        var days: [DayData] = []
        
        for i in 0..<daysCount {
            if let currentDate = calendar.date(byAdding: .day, value: i, to: startDay) {
                // Find if this day is part of any sprint
                if let sprintData = getDayScoreFromSprints(currentDate) {
                    days.append(sprintData)
                } else {
                    // Not part of any sprint, add with nil score
                    days.append(DayData(date: currentDate, score: nil))
                }
            }
        }
        
        return days
    }
    
    // Get day score from any sprint that contains this day
    private func getDayScoreFromSprints(_ date: Date) -> DayData? {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        
        for sprint in sprintStore.sprints {
            let sprintStart = calendar.startOfDay(for: sprint.startDate)
            let sprintEnd = calendar.startOfDay(for: sprint.endDate)
            
            // Check if day is in sprint range
            if day >= sprintStart && day <= sprintEnd {
                // Filter efforts for this sprint
                let sprintEfforts = sprintStore.efforts.filter { effort in
                    let effortDate = calendar.startOfDay(for: effort.date)
                    return effortDate >= sprintStart && effortDate <= sprintEnd
                }
                
                // Calculate scores for this sprint
                let scores = sprint.dailyScores(for: sprintEfforts)
                
                // Find the day index in the sprint
                if let dayIndex = calendar.dateComponents([.day], from: sprintStart, to: day).day,
                   dayIndex >= 0 && dayIndex < scores.count {
                    // Get the score for this day
                    let score = scores[dayIndex]
                    return DayData(date: date, score: score)
                }
            }
        }
        
        return nil
    }
}
