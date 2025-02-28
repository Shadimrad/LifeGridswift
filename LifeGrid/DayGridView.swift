//
//  DayGridView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

struct DayGridView: View {
    let dayData: [DayData]
    @Binding var zoomedDay: DayData?
    let animationNamespace: Namespace.ID
    
    // Configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let cellSize: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Days grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayData) { day in
                    // If day == zoomedDay, we hide it from the grid
                    if day != zoomedDay {
                        Rectangle()
                            .fill(day.color)
                            .matchedGeometryEffect(id: day.id, in: animationNamespace)
                            .frame(width: cellSize, height: cellSize)
                            .cornerRadius(2)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    zoomedDay = day
                                }
                            }
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
}

// Preview provider
struct DayGridView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @Namespace private var namespace
        @State private var zoomed: DayData? = nil
        
        var body: some View {
            // Create dummy day data for preview
            let dummyDays = (0..<14).map { i -> DayData in
                let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                // For preview, assign a random score for even-indexed days, nil for odd.
                let score: Double? = (i % 2 == 0) ? Double.random(in: 0...1) : nil
                return DayData(date: date, score: score)
            }
            
            return DayGridView(
                dayData: dummyDays,
                zoomedDay: $zoomed,
                animationNamespace: namespace
            )
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
