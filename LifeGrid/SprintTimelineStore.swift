//
//  SprintTimelineStore.swift (Previously LifetimeGridStore)
//  LifeGrid
//

import Foundation
import Combine

class LifetimeGridStore: ObservableObject {
    // References to other environment objects
    var userSettings: UserSettings
    var sprintStore: SprintStore
    
    // Published data
    @Published var lifetimeData: [YearData] = []
    
    // Initialize with required dependencies
    init(userSettings: UserSettings, sprintStore: SprintStore) {
        self.userSettings = userSettings
        self.sprintStore = sprintStore
        generateSprintTimelineData()
    }
    
    // Generate timeline data based on sprints
    func generateSprintTimelineData() {
        lifetimeData = []
        
        // If no sprints, just return
        if sprintStore.sprints.isEmpty {
            return
        }
        
        // Get date ranges from all sprints
        let calendar = Calendar.current
        
        // Find the earliest sprint start date and latest sprint end date
        let earliestDate = sprintStore.sprints.map { $0.startDate }.min() ?? Date()
        let latestDate = sprintStore.sprints.map { $0.endDate }.max() ?? Date()
        
        // Get the years covered by all sprints
        let earliestYear = calendar.component(.year, from: earliestDate)
        let latestYear = calendar.component(.year, from: latestDate)
        
        // Generate data for each year from earliest to latest
        for year in earliestYear...latestYear {
            // Create start and end date for the year
            var startDateComponents = DateComponents()
            startDateComponents.year = year
            startDateComponents.month = 1
            startDateComponents.day = 1
            
            var endDateComponents = DateComponents()
            endDateComponents.year = year
            endDateComponents.month = 12
            endDateComponents.day = 31
            
            guard let startDate = calendar.date(from: startDateComponents),
                  let endDate = calendar.date(from: endDateComponents) else {
                continue
            }
            
            // Generate days for this year
            let daysData = sprintStore.generateDayDataForRange(startDate: startDate, endDate: endDate)
            
            // Create year data
            let yearData = YearData(
                year: year,
                startDate: startDate,
                endDate: endDate,
                days: daysData
            )
            
            lifetimeData.append(yearData)
        }
    }
    
    // The original age-based method, kept for reference but no longer used
    func generateLifetimeData() {
        // Instead of using this method, we now call generateSprintTimelineData()
        generateSprintTimelineData()
    }
}
