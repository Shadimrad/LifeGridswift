import SwiftUI
import Charts

// MARK: - Data Structures

struct DailyScorePoint: Identifiable {
    var id = UUID()
    var date: Date
    var score: Double
}

struct TrendLinePoint: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double
}

struct TrendChartData {
    var dailyScores: [DailyScorePoint] = []
    var overallTrend: [TrendLinePoint] = []
    var weeklyTrend: [TrendLinePoint] = []
    var fourDayTrend: [TrendLinePoint] = []
}

// MARK: - Fixed Chart Rendering Function

@available(iOS 16.0, *)
private func createFixedChart(
    chartData: TrendChartData,
    showShortTermTrends: Bool
) -> some View {
    
    Chart {
        // 1) Daily Scores (blue line and points)
        ForEach(chartData.dailyScores) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Score", dataPoint.score)
            )
            .foregroundStyle(by: .value("Series", "DailyScore"))
            .interpolationMethod(.catmullRom)
        }
        
        ForEach(chartData.dailyScores) { dataPoint in
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Score", dataPoint.score)
            )
            .foregroundStyle(by: .value("Series", "DailyScore"))
            .symbolSize(30)
        }
        
        // 2) Overall Trend (purple line, two points)
        let overallPoints = chartData.overallTrend
        if overallPoints.count >= 2 {
            let firstPoint = overallPoints.first!
            let lastPoint = overallPoints.last!
            
            LineMark(
                x: .value("Date", firstPoint.date),
                y: .value("Overall", firstPoint.value)
            )
            .foregroundStyle(by: .value("Series", "OverallTrend"))
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            LineMark(
                x: .value("Date", lastPoint.date),
                y: .value("Overall", lastPoint.value)
            )
            .foregroundStyle(by: .value("Series", "OverallTrend"))
            .lineStyle(StrokeStyle(lineWidth: 3))
        }
        
        // 3) Weekly Trend (green dashed line, two points)
        let weeklyPoints = chartData.weeklyTrend
        if showShortTermTrends && weeklyPoints.count >= 2 {
            let firstPoint = weeklyPoints.first!
            let lastPoint = weeklyPoints.last!
            
            LineMark(
                x: .value("Date", firstPoint.date),
                y: .value("Weekly", firstPoint.value)
            )
            .foregroundStyle(by: .value("Series", "WeeklyTrend"))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            
            LineMark(
                x: .value("Date", lastPoint.date),
                y: .value("Weekly", lastPoint.value)
            )
            .foregroundStyle(by: .value("Series", "WeeklyTrend"))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
        }
        
        // 4) 4-Day Trend (red dotted line, two points)
        let fourDayPoints = chartData.fourDayTrend
        if showShortTermTrends && fourDayPoints.count >= 2 {
            let firstPoint = fourDayPoints.first!
            let lastPoint = fourDayPoints.last!
            
            LineMark(
                x: .value("Date", firstPoint.date),
                y: .value("4-Day", firstPoint.value)
            )
            .foregroundStyle(by: .value("Series", "FourDayTrend"))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
            
            LineMark(
                x: .value("Date", lastPoint.date),
                y: .value("4-Day", lastPoint.value)
            )
            .foregroundStyle(by: .value("Series", "FourDayTrend"))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
        }
    }
    .chartYScale(domain: 0...1.1)
    .chartForegroundStyleScale([
        "DailyScore": .blue,
        "OverallTrend": .purple,
        "WeeklyTrend": .green,
        "FourDayTrend": .red
    ])
    .chartXAxis {
        AxisMarks { value in
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    Text(date, format: .dateTime.day().month())
                        .font(.caption)
                }
            }
        }
    }
    .frame(height: 300)
}

// MARK: - Trend Analysis View

@available(iOS 16.0, *)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Score Trends")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TrendPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                if let trendChartData = generateChartData() {
                    // Chart and Legend
                    VStack(alignment: .leading, spacing: 16) {
                        createFixedChart(
                            chartData: trendChartData,
                            showShortTermTrends: selectedPeriod != .week
                        )
                        
                        // Legend
                        HStack(spacing: 30) {
                            LegendItem(color: .blue, label: "Daily Score")
                            LegendItem(color: .purple, label: "Overall")
                            if selectedPeriod != .week {
                                LegendItem(color: .green, label: "Weekly")
                                LegendItem(color: .red, label: "4-Day")
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal)
                    
                    // Trend Analysis Information
                    if let analysis = analyzeTrends(trendChartData) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Trend Analysis")
                                .font(.title3)
                                .bold()
                            
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
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                } else {
                    Text("Not enough data to calculate trends")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Chart Data Generation
    
    private func generateChartData() -> TrendChartData? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the start date based on selected period
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: today) else {
            return nil
        }
        
        // Generate day data from sprintStore (assumes your sprintStore provides this method)
        let dayData = sprintStore.generateDayDataForRange(startDate: startDate, endDate: today)
        
        // Filter out days without scores
        let daysWithScores = dayData.compactMap { day -> DailyScorePoint? in
            guard let score = day.score else { return nil }
            return DailyScorePoint(date: day.date, score: score)
        }.sorted { $0.date < $1.date }
        
        // Need at least two days to calculate trends
        guard daysWithScores.count >= 2 else { return nil }
        
        var chartData = TrendChartData(dailyScores: daysWithScores)
        
        // Calculate overall trend (using linear regression)
        if let (slope, intercept) = calculateLinearRegression(for: daysWithScores) {
            let firstDate = daysWithScores.first!.date
            let lastDate = daysWithScores.last!.date
            let dayDiff = Double(Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0)
            let startValue = intercept
            let endValue = intercept + slope * dayDiff
            
            chartData.overallTrend = [
                TrendLinePoint(date: firstDate, value: max(0, min(1, startValue))),
                TrendLinePoint(date: lastDate, value: max(0, min(1, endValue)))
            ]
        }
        
        // Calculate weekly trend (last 7 days)
        if daysWithScores.count >= 7 {
            let weekData = Array(daysWithScores.suffix(7))
            if let (slope, intercept) = calculateLinearRegression(for: weekData) {
                let firstDate = weekData.first!.date
                let lastDate = weekData.last!.date
                let startValue = intercept
                let endValue = intercept + slope * 6.0  // 6-day span
                chartData.weeklyTrend = [
                    TrendLinePoint(date: firstDate, value: max(0, min(1, startValue))),
                    TrendLinePoint(date: lastDate, value: max(0, min(1, endValue)))
                ]
            }
        }
        
        // Calculate 4-day trend (last 4 days)
        if daysWithScores.count >= 4 {
            let fourDayData = Array(daysWithScores.suffix(4))
            if let (slope, intercept) = calculateLinearRegression(for: fourDayData) {
                let firstDate = fourDayData.first!.date
                let lastDate = fourDayData.last!.date
                let startValue = intercept
                let endValue = intercept + slope * 3.0  // 3-day span
                chartData.fourDayTrend = [
                    TrendLinePoint(date: firstDate, value: max(0, min(1, startValue))),
                    TrendLinePoint(date: lastDate, value: max(0, min(1, endValue)))
                ]
            }
        }
        
        return chartData
    }
    
    // MARK: - Linear Regression Calculation
    
    private func calculateLinearRegression(for points: [DailyScorePoint]) -> (slope: Double, intercept: Double)? {
        guard points.count >= 2 else { return nil }
        
        let calendar = Calendar.current
        let n = Double(points.count)
        let firstDate = points.first!.date
        
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        for point in points {
            let dayDiff = Double(calendar.dateComponents([.day], from: firstDate, to: point.date).day ?? 0)
            let x = dayDiff
            let y = point.score
            
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }
        
        let denominator = n * sumX2 - sumX * sumX
        if abs(denominator) < 0.0001 { return nil }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        return (slope, intercept)
    }
    
    // MARK: - Trend Analysis
    
    private func analyzeTrends(_ chartData: TrendChartData) -> (slope4Day: Double, slopeWeek: Double, slopeOverall: Double)? {
        var slope4Day: Double = 0
        var slopeWeek: Double = 0
        var slopeOverall: Double = 0
        
        guard chartData.overallTrend.count >= 2 else { return nil }
        
        let overallPoints = chartData.overallTrend
        let overallStartValue = overallPoints[0].value
        let overallEndValue = overallPoints[1].value
        let overallDays = Double(Calendar.current.dateComponents([.day], from: overallPoints[0].date, to: overallPoints[1].date).day ?? 1)
        slopeOverall = (overallEndValue - overallStartValue) / overallDays
        
        if chartData.weeklyTrend.count >= 2 {
            let weekPoints = chartData.weeklyTrend
            let weekStartValue = weekPoints[0].value
            let weekEndValue = weekPoints[1].value
            let weekDays = Double(Calendar.current.dateComponents([.day], from: weekPoints[0].date, to: weekPoints[1].date).day ?? 1)
            slopeWeek = (weekEndValue - weekStartValue) / weekDays
        } else {
            slopeWeek = slopeOverall
        }
        
        if chartData.fourDayTrend.count >= 2 {
            let fourDayPoints = chartData.fourDayTrend
            let fourDayStartValue = fourDayPoints[0].value
            let fourDayEndValue = fourDayPoints[1].value
            let fourDayDays = Double(Calendar.current.dateComponents([.day], from: fourDayPoints[0].date, to: fourDayPoints[1].date).day ?? 1)
            slope4Day = (fourDayEndValue - fourDayStartValue) / fourDayDays
        } else {
            slope4Day = slopeWeek
        }
        
        return (slope4Day, slopeWeek, slopeOverall)
    }
    
    // MARK: - Trend Description Helper
    
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

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 20, height: 3)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stat Row Component

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

#if DEBUG
@available(iOS 16.0, *)
struct TrendAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let sprintStore = SprintStore() // Initialize with sample data as needed
        return TrendAnalysisView()
            .environmentObject(sprintStore)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Trend Analysis Preview")
    }
}
#endif
