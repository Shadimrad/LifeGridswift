//
// HeatMapView Enhancement
// Update your HeatMapView.swift file with these changes
//

import SwiftUI

struct HeatMapView: View {
    let dayData: [DayData]
    @Binding var zoomedDay: DayData?
    let animationNamespace: Namespace.ID
    
    // Configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let cellSize: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Overview")
                .font(.headline)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(dayData) { day in
                        // If day == zoomedDay, we hide it from the grid
                        if day != zoomedDay {
                            Rectangle()
                                .fill(day.color) // Use extension property for consistent coloring
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
            
            // Legend
            HStack(spacing: 16) {
                ForEach(0...4, id: \.self) { level in
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(getColorForLevel(Double(level) / 4.0))
                            .frame(width: cellSize, height: cellSize)
                            .cornerRadius(2)
                        
                        Text(getLabelForLevel(level))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
    
    // Gets color for legend based on activity level - using same logic as extension
    private func getColorForLevel(_ level: Double) -> Color {
        let hue: Double = 0.33 // Green hue
        let minBrightness: Double = 0.4
        let maxBrightness: Double = 0.95
        let minSaturation: Double = 0.5
        let maxSaturation: Double = 0.9
        
        // Linear interpolation: higher score gives higher saturation and lower brightness
        let brightness = maxBrightness - (maxBrightness - minBrightness) * level
        let saturation = minSaturation + (maxSaturation - minSaturation) * level
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    // Get label for legend level
    private func getLabelForLevel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        case 4: return "Max"
        default: return ""
        }
    }
}
