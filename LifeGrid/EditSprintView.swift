//
//  EditSprintView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//
import SwiftUI

struct EditSprintView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var sprintName: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var goals: [Goal]
    @State private var showingAddGoal = false
    @State private var editingGoalIndex: Int? = nil
    
    private let originalSprint: Sprint
    
    init(sprint: Sprint) {
        self.originalSprint = sprint
        _sprintName = State(initialValue: sprint.name)
        _startDate = State(initialValue: sprint.startDate)
        _endDate = State(initialValue: sprint.endDate)
        _goals = State(initialValue: sprint.goals)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sprint Info")) {
                    TextField("Sprint Name", text: $sprintName)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Goals")) {
                    ForEach(goals.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(goals[index].title)
                                    .fontWeight(.medium)
                                Text("\(goals[index].targetHours, specifier: "%.1f") hrs • \(Int(goals[index].weight * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editingGoalIndex = index
                                showingAddGoal = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete(perform: deleteGoal)
                    
                    Button("Add Goal") {
                        editingGoalIndex = nil
                        showingAddGoal = true
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Edit Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                if let index = editingGoalIndex {
                    // Edit existing goal
                    EditGoalView(goal: goals[index]) { updatedGoal in
                        goals[index] = updatedGoal
                    }
                } else {
                    // Add new goal
                    AddGoalView { newGoal in
                        goals.append(newGoal)
                    }
                }
            }
        }
    }
    
    private func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
    
    private func saveChanges() {
        let updatedSprint = Sprint(
            id: originalSprint.id,
            name: sprintName,
            startDate: startDate,
            endDate: endDate,
            goals: goals
        )
        
        sprintStore.updateSprint(updatedSprint)
        dismiss()
    }
}

// EditGoalView for updating existing goals
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
}
