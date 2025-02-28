
//
//  MainView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//
import SwiftUI

struct MainView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var dayDataArray: [DayData] = []
    @State private var zoomedDay: DayData? = nil
    @StateObject var sprintStore = SprintStore()

    
    // For testing, we use a default sprint.
    // You can later update this to use a sprint that the user creates.
    @State private var currentSprint = Sprint(
        name: "My Sprint",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
        goals: [
            Goal(title: "Study", targetHours: 2.0, weight: 0.5),
            Goal(title: "Exercise", targetHours: 1.0, weight: 0.3)
        ]
    )
    @State private var efforts: [Effort] = [] // No logged efforts yet
    
    @Namespace private var animationNamespace
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Hero section
                    ZStack {
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                        .edgesIgnoringSafeArea(.top)
                        VStack {
                            Text("LifeGrid")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            Text("Viewing \(userSettings.yearsToView) Years")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Grid below hero
                    VStack(spacing: 16) {
                        if dayDataArray.isEmpty {
                            Spacer()
                            Text("No grid to display yet.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                            Spacer()
                        } else {
                            DayGridView(
                                dayData: dayDataArray,
                                zoomedDay: $zoomedDay,
                                animationNamespace: animationNamespace
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    // Auto-generate grid data when MainView appears.
                    dayDataArray = generateDayData(for: currentSprint, with: efforts)
                }
                
                // Zoom overlay if a day is tapped.
                if let day = zoomedDay {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation { zoomedDay = nil }
                        }
                        .zIndex(1)
                    Rectangle()
                        .fill(day.color)
                        .matchedGeometryEffect(id: day.id, in: animationNamespace)
                        .frame(width: 200, height: 200)
                        .cornerRadius(16)
                        .overlay(
                            VStack {
                                Text(day.date, style: .date)
                                    .font(.headline)
                                if let score = day.score {
                                    Text("Score: \(String(format: "%.2f", score))")
                                } else {
                                    Text("No Data Logged")
                                }
                                Button("Close") {
                                    withAnimation { zoomedDay = nil }
                                }
                                .buttonStyle(.bordered)
                                .padding(.top, 8)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(12)
                        )
                        .zIndex(2)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationLink("Account") {
                    AccountView()
                }
            }
        }
    }
    
    // Function that generates grid data based on a sprint's date range and efforts.
    func generateDayData(for sprint: Sprint, with efforts: [Effort]) -> [DayData] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: sprint.startDate)
        guard let daysCount = calendar.dateComponents([.day], from: startDate, to: sprint.endDate).day.map({ $0 + 1 }) else {
            return []
        }
        let scores = sprint.dailyScores(for: efforts)
        var dayDataArray: [DayData] = []
        for i in 0..<daysCount {
            if let currentDate = calendar.date(byAdding: .day, value: i, to: startDate) {
                let score = i < scores.count ? scores[i] : nil
                dayDataArray.append(DayData(date: currentDate, score: score))
            }
        }
        return dayDataArray
    }
}
