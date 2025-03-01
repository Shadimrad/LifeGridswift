//
//  SprintsView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

struct SprintsView: View {
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var showingAddSprint = false
    @State private var showingDeleteAlert = false
    @State private var sprintToDelete: Sprint? = nil
    
    var body: some View {
        List {
            if sprintStore.sprints.isEmpty {
                emptySprintsView
            } else {
                sprintsList
            }
        }
        .navigationTitle("Your Sprints")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSprint = true
                }) {
                    Label("Add Sprint", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSprint) {
            AddSprintView()
                .environmentObject(sprintStore)
        }
        .alert("Delete Sprint", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let sprint = sprintToDelete {
                    deleteSprintWithEfforts(sprint)
                }
            }
        } message: {
            if let sprint = sprintToDelete {
                Text("Are you sure you want to delete \"\(sprint.name)\"? This will also delete all related effort data.")
            } else {
                Text("Are you sure you want to delete this sprint?")
            }
        }
    }
    
    // Empty state view when no sprints exist
    private var emptySprintsView: some View {
        Section {
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("No Sprints Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first sprint to start tracking your progress! Sprints help you focus on goals for a specific time period.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingAddSprint = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create First Sprint")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding(.vertical, 40)
            .listRowBackground(Color.clear)
        }
    }
    
    // List of user's sprints
    private var sprintsList: some View {
        ForEach(sprintStore.sprints.sorted(by: { $0.startDate > $1.startDate })) { sprint in
            NavigationLink(destination: SprintDetailView(sprint: sprint).environmentObject(sprintStore)) {
                sprintRow(for: sprint)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    sprintToDelete = sprint
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                NavigationLink(destination: EditSprintView(sprint: sprint).environmentObject(sprintStore)) {
                    Label("Edit", systemImage: "pencil")
                }                .tint(.blue)
            }
        }
    }
    
    // Row for a single sprint
    private func sprintRow(for sprint: Sprint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(sprint.name)
                    .font(.headline)
                
                Spacer()
                
                // Show green badge for active sprints
                if isSprintActive(sprint) {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            Text("\(sprint.startDate, style: .date) - \(sprint.endDate, style: .date)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Show sprint progress
            if isSprintActive(sprint) || isPastSprint(sprint) {
                let progress = calculateSprintProgress(sprint)
                HStack {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.top, 4)
            }
            
            // Show number of goals
            Text("\(sprint.goals.count) goal\(sprint.goals.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    // Delete a sprint and its related efforts
    private func deleteSprintWithEfforts(_ sprint: Sprint) {
        // First, filter out all efforts related to this sprint's goals
        let goalIds = Set(sprint.goals.map { $0.id })
        sprintStore.efforts = sprintStore.efforts.filter { !goalIds.contains($0.goalId) }
        
        // Then remove the sprint
        sprintStore.sprints.removeAll { $0.id == sprint.id }
        
        // Save changes
        sprintStore.saveSprints()
        sprintStore.saveEfforts()
    }
    
    // Helper to check if a sprint is currently active
    private func isSprintActive(_ sprint: Sprint) -> Bool {
        let today = Date()
        return today >= sprint.startDate && today <= sprint.endDate
    }
    
    // Helper to check if a sprint is in the past
    private func isPastSprint(_ sprint: Sprint) -> Bool {
        return Date() > sprint.endDate
    }
    
    // Calculate sprint progress percentage
    private func calculateSprintProgress(_ sprint: Sprint) -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // If sprint hasn't started, progress is 0
        if today < sprint.startDate {
            return 0
        }
        
        // If sprint is completed, progress is 1
        if today > sprint.endDate {
            return 1
        }
        
        // Calculate days elapsed and total days
        let totalDays = calendar.dateComponents([.day], from: sprint.startDate, to: sprint.endDate).day ?? 1
        let daysElapsed = calendar.dateComponents([.day], from: sprint.startDate, to: today).day ?? 0
        
        return min(1.0, Double(daysElapsed) / Double(totalDays))
    }
}

// Add Sprint View
struct AddSprintView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var sprintName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // One week later
    @State private var goals: [Goal] = []
    @State private var showingAddGoal = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sprint Info")) {
                    TextField("Sprint Name", text: $sprintName)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                Section(header: Text("Goals")) {
                    if goals.isEmpty {
                        Text("No goals added yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(goals) { goal in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(goal.title)
                                        .fontWeight(.medium)
                                    
                                    Text("\(goal.targetHours, specifier: "%.1f") hrs/day • \(Int(goal.weight * 100))% weight")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteGoal)
                    }
                    
                    Button("Add Goal") {
                        showingAddGoal = true
                    }
                }
                
                Section {
                    Button("Create Sprint") {
                        createSprint()
                    }
                    .disabled(sprintName.isEmpty || goals.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(sprintName.isEmpty || goals.isEmpty ? .gray : .blue)
                }
            }
            .navigationTitle("New Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView { newGoal in
                    goals.append(newGoal)
                }
                .environmentObject(sprintStore)
            }
        }
    }
    
    private func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
    
    private func createSprint() {
        let newSprint = Sprint(
            name: sprintName,
            startDate: startDate,
            endDate: endDate,
            goals: goals
        )
        
        sprintStore.sprints.append(newSprint)
        sprintStore.saveSprints()
        dismiss()
    }
}

// Add Goal View
struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sprintStore: SprintStore
    @State private var goalTitle = ""
    @State private var targetHours = ""
    @State private var weight = ""
    
    var onSave: (Goal) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Goal Title")) {
                    TextField("Enter goal title", text: $goalTitle)
                }
                
                Section(header: Text("Target Hours Per Day")) {
                    TextField("e.g., 2.0", text: $targetHours)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Weight (%)")) {
                    TextField("e.g., 40", text: $weight)
                        .keyboardType(.numberPad)
                    
                    Text("Weight represents how much this goal contributes to your overall sprint score.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !goalTitle.isEmpty &&
        Double(targetHours) != nil &&
        Double(weight) != nil
    }
    
    private func saveGoal() {
        guard isValid else { return }
        
        let newGoal = Goal(
            title: goalTitle,
            targetHours: Double(targetHours) ?? 0,
            weight: (Double(weight) ?? 0) / 100 // Convert percentage to decimal
        )
        
        onSave(newGoal)
        dismiss()
    }
}

struct SprintsView_Previews: PreviewProvider {
    static var previews: some View {
        let sprintStore = SprintStore()
        return NavigationStack {
            SprintsView()
                .environmentObject(sprintStore)
        }
    }
}
