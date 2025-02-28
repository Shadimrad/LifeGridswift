//
//  TrendAnalysisView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//

import SwiftUI
import Charts

// Data model for trend analysis
struct TrendData: Identifiable {
    var id = UUID()
    var date: Date
    var score: Double
    var trend4Days: Double?
    var trendWeek: Double?
    var trend10Days: Double?
    var overallTrend: Double?
}

// View for displaying trend analysis
struct TrendAnalysisView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var selectedPeriod: TrendPeriod = .week
    
    enum TrendPeriod: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Trends")
                .font(.headline)
            
            // Period selector
            Picker("Period", selection: $selectedPeriod) {
                ForEach(TrendPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            if let trendData = generateTrendData() {
                // Score trend chart
                if #available(iOS 16.0, *) {
                    Chart {
                        // Daily scores
                        ForEach(trendData) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Score", dataPoint.score)
                            )
                            .foregroundStyle(.blue)
                            .symbol {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        
                        // 4-Day trend line
                        if selectedPeriod != .week {
                            ForEach(trendData.filter { $0.trend4Days != nil }) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("4-Day Trend", dataPoint.trend4Days!)
                                )
                                .foregroundStyle(.red)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            }
                        }
                        
                        // Weekly trend line
                        ForEach(trendData.filter { $0.trendWeek != nil }) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Weekly Trend", dataPoint.trendWeek!)
                            )
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                        
                        // Overall trend line
                        ForEach(trendData.filter { $0.overallTrend != nil }) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Overall Trend", dataPoint.overallTrend!)
                            )
                            .foregroundStyle(.purple)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
                        }
                    }
                    .chartYScale(domain: -0.1...1.1)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: selectedPeriod.days > 30 ? 7 : 1)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.day().month())
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                } else {
                    // Fallback for iOS 15
                    Text("Trends chart requires iOS 16+")
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                }
                
                // Trend analysis information
                if let analysis = analyzeTrends(trendData) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Trend Analysis")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Group {
                            StatRow(
                                title: "4-Day Trend",
                                value: analysis.slope4Day,
                                description: trendDescription(analysis.slope4Day)
                            )
                            
                            StatRow(
                                title: "Weekly Trend",
                                value: analysis.slopeWeek,
                                description: trendDescription(analysis.slopeWeek)
                            )
                            
                            StatRow(
                                title: "Overall Trend",
                                value: analysis.slopeOverall,
                                description: trendDescription(analysis.slopeOverall)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            } else {
                Text("Not enough data to calculate trends")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private func generateTrendData() -> [TrendData]? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get start date based on selected period
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: today) else {
            return nil
        }
        
        // Get raw day data from sprint store
        let rawDayData = sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        
        // Need at least 4 days of data for trend analysis
        guard rawDayData.count >= 4 else {
            return nil
        }
        
        // Convert to trend data format
        var trendDataPoints: [TrendData] = []
        
        for dayData in rawDayData {
            if let score = dayData.score {
                trendDataPoints.append(TrendData(
                    date: dayData.date,
                    score: score,
                    trend4Days: nil,
                    trendWeek: nil,
                    trend10Days: nil,
                    overallTrend: nil
                ))
            }
        }
        
        // Sort by date
        trendDataPoints.sort { $0.date < $1.date }
        
        // Calculate trend lines
        if trendDataPoints.count >= 4 {
            // Calculate trends
            let overall = calculateTrendLine(data: trendDataPoints)
            let last4Days = calculateTrendLine(data: Array(trendDataPoints.suffix(min(4, trendDataPoints.count))))
            let lastWeek = calculateTrendLine(data: Array(trendDataPoints.suffix(min(7, trendDataPoints.count))))
            
            // Apply trend values to data points
            for i in 0..<trendDataPoints.count {
                // Overall trend
                if let overallSlope = overall.slope, let overallIntercept = overall.intercept {
                    let daysSinceStart = Calendar.current.dateComponents([.day], from: trendDataPoints[0].date, to: trendDataPoints[i].date).day ?? 0
                    trendDataPoints[i].overallTrend = overallIntercept + overallSlope * Double(daysSinceStart)
                }
                
                // Only add 4-day and weekly trends to their respective periods
                if i >= trendDataPoints.count - 4 {
                    if let slope4Day = last4Days.slope, let intercept4Day = last4Days.intercept {
                        let daysSince = Calendar.current.dateComponents([.day], from: trendDataPoints[trendDataPoints.count - 4].date, to: trendDataPoints[i].date).day ?? 0
                        trendDataPoints[i].trend4Days = intercept4Day + slope4Day * Double(daysSince)
                    }
                }
                
                if i >= trendDataPoints.count - 7 {
                    if let slopeWeek = lastWeek.slope, let interceptWeek = lastWeek.intercept {
                        let daysSince = Calendar.current.dateComponents([.day], from: trendDataPoints[max(0, trendDataPoints.count - 7)].date, to: trendDataPoints[i].date).day ?? 0
                        trendDataPoints[i].trendWeek = interceptWeek + slopeWeek * Double(daysSince)
                    }
                }
            }
        }
        
        return trendDataPoints
    }
    
    // Calculate linear regression for trend line
    private func calculateTrendLine(data: [TrendData]) -> (slope: Double?, intercept: Double?) {
        guard data.count >= 2 else {
            return (nil, nil)
        }
        
        let n = Double(data.count)
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        // Convert dates to day numbers (0, 1, 2, etc.)
        let startDate = data[0].date
        let calendar = Calendar.current
        
        for (i, point) in data.enumerated() {
            let x = Double(calendar.dateComponents([.day], from: startDate, to: point.date).day ?? i)
            let y = point.score
            
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }
        
        // Calculate slope and intercept
        let denominator = n * sumX2 - sumX * sumX
        if denominator == 0 {
            return (nil, nil)
        }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        return (slope, intercept)
    }
    
    // Analyze trends and return slope values
    private func analyzeTrends(_ data: [TrendData]) -> (slope4Day: Double, slopeWeek: Double, slopeOverall: Double)? {
        guard data.count >= 7 else {
            return nil
        }
        
        let last4Days = Array(data.suffix(min(4, data.count)))
        let lastWeek = Array(data.suffix(min(7, data.count)))
        
        let overall = calculateTrendLine(data: data)
        let last4 = calculateTrendLine(data: last4Days)
        let week = calculateTrendLine(data: lastWeek)
        
        guard let slopeOverall = overall.slope,
              let slope4Day = last4.slope,
              let slopeWeek = week.slope else {
            return nil
        }
        
        return (slope4Day, slopeWeek, slopeOverall)
    }
    
    // Helper to provide text description of trend
    private func trendDescription(_ slope: Double) -> String {
        if slope > 0.02 {
            return "Strong positive trend"
        } else if slope > 0.005 {
            return "Positive trend"
        } else if slope < -0.02 {
            return "Strong negative trend"
        } else if slope < -0.005 {
            return "Negative trend"
        } else {
            return "Stable"
        }
    }
}

// Stat row component
struct StatRow: View {
    let title: String
    let value: Double
    let description: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text(String(format: "%.4f", value))
                    .fontWeight(.medium)
                    .foregroundColor(trendColor(value))
                
                Image(systemName: trendIcon(value))
                    .foregroundColor(trendColor(value))
            }
            .frame(width: 100, alignment: .trailing)
            
            Text(description)
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .trailing)
        }
    }
    
    private func trendIcon(_ value: Double) -> String {
        if value > 0.005 {
            return "arrow.up"
        } else if value < -0.005 {
            return "arrow.down"
        } else {
            return "arrow.right"
        }
    }
    
    private func trendColor(_ value: Double) -> Color {
        if value > 0.005 {
            return .green
        } else if value < -0.005 {
            return .red
        } else {
            return .gray
        }
    }
}
