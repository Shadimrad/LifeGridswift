//
//  SprintDetailView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/27/25.
//

import SwiftUI

struct SprintDetailView: View {
    let sprint: Sprint
    
    var body: some View {
        VStack(spacing: 16) {
            Text(sprint.name)
                .font(.title)
                .bold()
            Text("Start Date: \(sprint.startDate, style: .date)")
            Text("End Date: \(sprint.endDate, style: .date)")
            
            // List the goals for this sprint.
            if sprint.goals.isEmpty {
                Text("No goals defined for this sprint.")
                    .foregroundColor(.gray)
            } else {
                List(sprint.goals) { goal in
                    HStack {
                        Text(goal.title)
                        Spacer()
                        Text("\(goal.targetHours, specifier: "%.1f") hrs")
                        Text("(\(Int(goal.weight * 100))%)")
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sprint Details")
    }
}

struct SprintDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample sprint with one goal for preview purposes.
        let sampleSprint = Sprint(
            name: "Sample Sprint",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            goals: [
                Goal(title: "Study", targetHours: 2.0, weight: 0.5),
                Goal(title: "Exercise", targetHours: 1.0, weight: 0.3)
            ]
        )
        return NavigationStack {
            SprintDetailView(sprint: sampleSprint)
        }
    }
}
