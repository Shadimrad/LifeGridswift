//
//  DayData+Extensions.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/27/25.
//
import SwiftUI

extension DayData {
    var color: Color {
        if let score = score {
            // Define a green gradient from light to dark based on score
            let hue: Double = 0.33 // Green hue
            let minBrightness: Double = 0.4
            let maxBrightness: Double = 0.95
            let minSaturation: Double = 0.5
            let maxSaturation: Double = 0.9
            
            // Linear interpolation: higher score gives higher saturation and lower brightness
            let brightness = maxBrightness - (maxBrightness - minBrightness) * score
            let saturation = minSaturation + (maxSaturation - minSaturation) * score
            
            return Color(hue: hue, saturation: saturation, brightness: brightness)
        } else {
            // No data (regardless of past/future)
            return Color.gray.opacity(0.2)
        }
    }
    
    // Helper to determine text color based on background brightness
    var textColor: Color {
        if let score = score, score > 0.5 {
            // For darker backgrounds (high score), use white text
            return .white
        } else {
            // For lighter backgrounds (low/no score), use dark text
            return .primary
        }
    }
    
    // Helper to generate a descriptive label based on score
    var scoreLabel: String {
        if let score = score {
            let percentage = Int(score * 100)
            if percentage >= 90 {
                return "Excellent"
            } else if percentage >= 75 {
                return "Great"
            } else if percentage >= 60 {
                return "Good"
            } else if percentage >= 40 {
                return "Fair"
            } else if percentage >= 20 {
                return "Poor"
            } else {
                return "Very Poor"
            }
        } else {
            return "No Data"
        }
    }
}
