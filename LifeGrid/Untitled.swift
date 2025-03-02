import Foundation

func statistics(for completions: [Double]) -> (mean: Double, median: Double, range: Double, stdDev: Double) {
    guard !completions.isEmpty else {
        fatalError("Array cannot be empty")
    }
    
    let mean = completions.reduce(0, +) / Double(completions.count)
    
    let sortedCompletions = completions.sorted()
    let midIndex = sortedCompletions.count / 2
    let median: Double
    if sortedCompletions.count % 2 == 0 {
        median = (sortedCompletions[midIndex - 1] + sortedCompletions[midIndex]) / 2
    } else {
        median = sortedCompletions[midIndex]
    }
    
    let range = sortedCompletions.max()! - sortedCompletions.min()!
    
    let variance = completions.map { pow($0 - mean, 2) }.reduce(0, +) / Double(completions.count - 1)
    let stdDev = sqrt(variance)
    
    return (mean, median, range, stdDev)
}
