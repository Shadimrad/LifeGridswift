//
//  LifeProgressCalculator.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//

import SwiftUI

// Life progress calculation utility
struct LifeProgressCalculator {
    
    // Calculate overall life progress (percentage of life completed)
    static func calculateLifeProgress(currentAge: Int, targetAge: Int) -> Double {
        guard targetAge > 0 else { return 0 }
        return min(Double(currentAge) / Double(targetAge), 1.0)
    }
    
    // Calculate detailed life statistics
    static func calculateLifeStats(currentAge: Int, targetAge: Int) -> LifeStatistics {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate birth date (approximated from current age)
        let birthYear = calendar.component(.year, from: now) - currentAge
        var birthDateComponents = DateComponents()
        birthDateComponents.year = birthYear
        birthDateComponents.month = calendar.component(.month, from: now)
        birthDateComponents.day = calendar.component(.day, from: now)
        let birthDate = calendar.date(from: birthDateComponents) ?? now
        
        // Calculate expected end date
        var endDateComponents = DateComponents()
        endDateComponents.year = birthYear + targetAge
        endDateComponents.month = calendar.component(.month, from: now)
        endDateComponents.day = calendar.component(.day, from: now)
        let endDate = calendar.date(from: endDateComponents) ?? now
        
        // Calculate total days in life
        let totalDays = calendar.dateComponents([.day], from: birthDate, to: endDate).day ?? 0
        
        // Calculate days lived so far
        let daysLived = calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0
        
        // Calculate days remaining
        let daysRemaining = max(0, totalDays - daysLived)
        
        // Calculate percentage completed
        let percentCompleted = totalDays > 0 ? (Double(daysLived) / Double(totalDays)) : 0
        
        // Calculate weeks lived and remaining
        let weeksLived = daysLived / 7
        let weeksRemaining = daysRemaining / 7
        
        return LifeStatistics(
            yearsLived: currentAge,
            yearsRemaining: targetAge - currentAge,
            daysLived: daysLived,
            daysRemaining: daysRemaining,
            weeksLived: weeksLived,
            weeksRemaining: weeksRemaining,
            percentCompleted: percentCompleted,
            birthDate: birthDate,
            projectedEndDate: endDate
        )
    }
}

// Life statistics data structure
struct LifeStatistics {
    let yearsLived: Int
    let yearsRemaining: Int
    let daysLived: Int
    let daysRemaining: Int
    let weeksLived: Int
    let weeksRemaining: Int
    let percentCompleted: Double
    let birthDate: Date
    let projectedEndDate: Date
    
    // Computed properties for formatted values
    var formattedPercentCompleted: String {
        return String(format: "%.1f%%", percentCompleted * 100)
    }
    
    var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
    
    var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: projectedEndDate)
    }
}

// Life statistics view component
struct LifeStatsView: View {
    let stats: LifeStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Life Progress")
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
                StatItem(title: "Years Lived", value: "\(stats.yearsLived)")
                StatItem(title: "Years Remaining", value: "\(stats.yearsRemaining)")
                StatItem(title: "Weeks Lived", value: "\(stats.weeksLived)")
                StatItem(title: "Weeks Remaining", value: "\(stats.weeksRemaining)")
                StatItem(title: "Days Lived", value: "\(stats.daysLived)")
                StatItem(title: "Days Remaining", value: "\(stats.daysRemaining)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
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

// Preview provider
struct LifeStatsView_Previews: PreviewProvider {
    static var previews: some View {
        LifeStatsView(stats: LifeProgressCalculator.calculateLifeStats(currentAge: 30, targetAge: 85))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
