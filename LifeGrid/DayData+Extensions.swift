//
//  DayData+Extensions.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/27/25.
//
import SwiftUI
extension DayData {
    var color: Color {
        let today = Calendar.current.startOfDay(for: Date())
        if date > today {
            // Future days: light gray.
            return Color.gray.opacity(0.3)
        } else if let score = score {
            // Define brightness range: score 0 -> maxBrightness (very light), score 1 -> minBrightness (dark)
            let maxBrightness: Double = 0.95
            let minBrightness: Double = 0.5
            // Linear interpolation: higher score gives lower brightness
            let brightness = maxBrightness - (maxBrightness - minBrightness) * score
            return Color(hue: 0.33, saturation: 1.0, brightness: brightness)
        } else {
            // Past days with no data: a default dark gray.
            return Color.gray.opacity(0.7)
        }
    }
}

