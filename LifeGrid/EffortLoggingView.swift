//
//  EffortLoggingView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/27/25.
//
import SwiftUI

struct EffortLoggingView: View {
    let sprint: Sprint
    let date: Date
    @State private var selectedGoalId: UUID?
    @State private var hoursInput: String = ""
    var onSave: (Effort) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Select Goal")) {
                ForEach(sprint.goals) { goal in
                    Button {
                        selectedGoalId = goal.id
                    } label: {
                        HStack {
                            Text(goal.title)
                            Spacer()
                            if selectedGoalId == goal.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Section(header: Text("Hours Completed")) {
                TextField("e.g., 2.0", text: $hoursInput)
                    .keyboardType(.decimalPad)
            }
            Button("Save") {
                guard let goalId = selectedGoalId, let hours = Double(hoursInput) else { return }
                let effort = Effort(goalId: goalId, date: date, hours: hours)
                onSave(effort)
            }
        }
        .navigationTitle("Log Effort")
    }
}
