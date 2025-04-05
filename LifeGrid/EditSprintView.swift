//
//  EditSprintView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/28/25.
//
import SwiftUI
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
    @State private var showWeightWarning = false  // New state for warning
    
    private let originalSprint: Sprint
    
    init(sprint: Sprint) {
        self.originalSprint = sprint
        _sprintName = State(initialValue: sprint.name)
        _startDate = State(initialValue: sprint.startDate)
        _endDate = State(initialValue: sprint.endDate)
        _goals = State(initialValue: sprint.goals)
    }
    
    // Calculate the total weight of all goals
    private var totalWeight: Double {
        goals.reduce(0) { $0 + $1.weight }
    }
    
    // Check that total weight is at most 100%
    private var isWeightValid: Bool {
        totalWeight <= 1.0
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
                        if isWeightValid {
                            saveChanges()
                        } else {
                            showWeightWarning = true
                        }
                    }
                    .disabled(sprintName.isEmpty || goals.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor((sprintName.isEmpty || goals.isEmpty) ? .gray : (isWeightValid ? .blue : .red))
                    .alert("Weight Limit Exceeded", isPresented: $showWeightWarning) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("The total weight of all goals cannot exceed 100%. Current total: \(Int(totalWeight * 100))%")
                    }
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
                    // Edit an existing goal
                    EditGoalView(goal: goals[index]) { updatedGoal in
                        goals[index] = updatedGoal
                    }
                } else {
                    // Add a new goal – pass in the current total weight for feedback
                    AddGoalView(currentTotalWeight: totalWeight) { newGoal in
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


// Mock Sprint separate from store, pulled from mock store

let mockSprint = SprintStore.mock.sprints.first!

#Preview {
    EditSprintView(sprint: mockSprint)
        .environmentObject(SprintStore.mock)
}
