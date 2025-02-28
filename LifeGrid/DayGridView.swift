//
//  DayGridView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

// MARK: - 6) Grid View and Day Cell (existing code)
// Displays day cells in a scrollable grid. Tapping a cell zooms it in.
struct DayGridView: View {
    let dayData: [DayData]
    @Binding var zoomedDay: DayData?
    let animationNamespace: Namespace.ID  // from parent
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayData) { day in
                    // If day == zoomedDay, we hide it from the grid
                    if day != zoomedDay {
                        Rectangle()
                            .fill(day.color)
                            .matchedGeometryEffect(id: day.id, in: animationNamespace)
                            .frame(width: 14, height: 14)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    zoomedDay = day
                                }
                            }
                    }
                }
            }
        }
    }
}



// Displays an individual day cell.
struct DayCell: View {
    let day: DayData
    @Binding var zoomedDay: DayData?
    
    let cellSize: CGFloat
    let animationNamespace: Namespace.ID
    
    var body: some View {
        ZStack {
            if zoomedDay == day {
                // Zoomed state: large cell with extra info.
                Rectangle()
                    .fill(day.color)
                    .matchedGeometryEffect(id: day.id, in: animationNamespace)
                    .frame(width: 200)
                    .cornerRadius(16)
                    .overlay(
                        VStack {
                            Text(day.date, style: .date)
                                .font(.headline)
                                .padding(.bottom, 4)
                            if let score = day.score {
                                Text("Score: \(String(format: "%.2f", score))")
                            } else {
                                Text("No Data Logged")
                            }
                            Button("Close") {
                                withAnimation {
                                    zoomedDay = nil
                                }
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 8)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                    )
                    .onTapGesture {
                        withAnimation {
                            zoomedDay = nil
                        }
                    }
            } else {
                // Normal state: small cell.
                Rectangle()
                    .fill(day.color)
                    .matchedGeometryEffect(id: day.id, in: animationNamespace)
                    .frame(width: cellSize, height: cellSize)
                    .cornerRadius(2)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            zoomedDay = day
                        }
                    }
            }
        }
    }
    

}
