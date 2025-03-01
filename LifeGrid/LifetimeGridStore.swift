//
//  LifetimeGridStore.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
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
        generateLifetimeData()
    }
    
    // Generate lifetime data based on user settings
    func generateLifetimeData() {
        lifetimeData = []
        
        let calendar = Calendar.current
        let currentAge = userSettings.currentAge
        let targetAge = userSettings.targetAge
        
        // Get current date and year
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        
        // Calculate birth year (approximate)
        let birthYear = currentYear - currentAge
        
        // Generate data for each year from birth year to target year
        for year in birthYear...(birthYear + targetAge) {
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
}
