//
//  SprintsView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/27/25.
//

import SwiftUI

struct SprintsView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var showingCreateSprint = false
    
    var body: some View {
        NavigationStack {
            List {
                if sprintStore.sprints.isEmpty {
                    Text("No sprints available. Tap 'Add Sprint' to create one.")
                        .foregroundColor(.gray)
                }
                ForEach(sprintStore.sprints) { sprint in
                    NavigationLink(sprint.name) {
                        SprintDetailView(sprint: sprint)
                    }
                }
            }
            .navigationTitle("My Sprints")
            .toolbar {
                Button("Add Sprint") {
                    showingCreateSprint = true
                }
            }
            .sheet(isPresented: $showingCreateSprint) {
                CreateSprintView { newSprint in
                    sprintStore.sprints.append(newSprint)
                }
            }
        }
    }
}


struct CreateSprintView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sprintName: String = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var goals: [Goal] = []  // This holds the sprint’s goals.
    
    // State variable to control presenting the AddGoalView sheet.
    @State private var showingAddGoal = false
    
    var onSave: (Sprint) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sprint Info")) {
                    TextField("Sprint Name", text: $sprintName)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                Section(header: Text("Goals")) {
                    // List the current goals.
                    ForEach(goals) { goal in
                        HStack {
                            Text(goal.title)
                            Spacer()
                            Text("\(goal.targetHours, specifier: "%.1f") hrs")
                            Text("(\(Int(goal.weight * 100))%)")
                        }
                    }
                    // Button to add a new goal.
                    Button("Add Goal") {
                        showingAddGoal = true
                    }
                }
                Button("Save Sprint") {
                    let newSprint = Sprint(
                        name: sprintName,
                        startDate: startDate,
                        endDate: endDate,
                        goals: goals
                    )
                    onSave(newSprint)
                    dismiss()
                }
            }
            .navigationTitle("Create Sprint")
            // Present the AddGoalView as a sheet.
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView { newGoal in
                    goals.append(newGoal)
                }
            }
        }
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var goalTitle: String = ""
    @State private var targetHours: String = ""
    @State private var weight: String = ""
    
    // Closure called when a new goal is saved.
    var onSave: (Goal) -> Void
    
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
            .navigationTitle("Add Goal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Validate inputs
                        if let target = Double(targetHours), let weightValue = Double(weight) {
                            // Convert weight percentage to a fraction (e.g., 40 becomes 0.40)
                            let newGoal = Goal(title: goalTitle, targetHours: target, weight: weightValue / 100)
                            onSave(newGoal)
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
}

struct SprintsView_Previews: PreviewProvider {
    static var previews: some View {
        SprintsView()
    }
}
