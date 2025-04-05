
import SwiftUI

struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var goalTitle: String
    @State private var targetHours: String
    @State private var weight: String
    
    private let originalGoal: Goal
    var onSave: (Goal) -> Void
    
    init(goal: Goal, onSave: @escaping (Goal) -> Void) {
        self.originalGoal = goal
        self.onSave = onSave
        _goalTitle = State(initialValue: goal.title)
        _targetHours = State(initialValue: String(format: "%.1f", goal.targetHours))
        _weight = State(initialValue: String(Int(goal.weight * 100)))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Goal Title")) {
                    TextField("Enter goal title", text: $goalTitle)
                }
                Section(header: Text("Target Hours")) {
                    TextField("e.g., 2.0", text: $targetHours)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Weight (%)")) {
                    TextField("e.g., 40", text: $weight)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Goal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let target = Double(targetHours), let weightValue = Double(weight) {
                            let updatedGoal = Goal(
                                id: originalGoal.id,
                                title: goalTitle,
                                targetHours: target,
                                weight: weightValue / 100
                            )
                            onSave(updatedGoal)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}//
//  EditGoalView.swift
//  LifeGrid
//
//  Created by Shaqayeq Rad on 4/5/25.
//

