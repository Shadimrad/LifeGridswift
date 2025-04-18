//
//  EffortManagementView.swift
//  LifeGrid
//
//  Created on 2/28/25.
//

import SwiftUI

// View for editing an existing effort
struct EditEffortView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var selectedGoalId: UUID
    @State private var hoursInput: String
    @State private var useTimeSelector = false
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String = ""
    @State private var showingDeleteConfirmation = false
    
    private let effort: Effort
    private let sprint: Sprint
    
    init(effort: Effort, sprint: Sprint) {
        self.effort = effort
        self.sprint = sprint
        
        _selectedGoalId = State(initialValue: effort.goalId)
        _hoursInput = State(initialValue: String(format: "%.1f", effort.hours))
        
        let calendar = Calendar.current
        _startTime = State(initialValue: effort.date)
        
        let endTimeComponent = calendar.dateComponents([.hour, .minute], from: effort.date)
        var endHour = endTimeComponent.hour ?? 0
        var endMinute = (endTimeComponent.minute ?? 0) + Int(effort.hours * 60)
        
        while endMinute >= 60 {
            endHour += 1
            endMinute -= 60
        }
        
        var endTimeComponents = DateComponents()
        endTimeComponents.year = calendar.component(.year, from: effort.date)
        endTimeComponents.month = calendar.component(.month, from: effort.date)
        endTimeComponents.day = calendar.component(.day, from: effort.date)
        endTimeComponents.hour = endHour
        endTimeComponents.minute = endMinute
        
        _endTime = State(initialValue: calendar.date(from: endTimeComponents) ?? effort.date.addingTimeInterval(effort.hours * 3600))
    }
    
    private var hoursFromTimeSelection: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: startTime, to: endTime)
        let minutes = components.minute ?? 0
        return Double(minutes) / 60.0
    }
    
    private var canSave: Bool {
        selectedGoalId != UUID() && (
            (useTimeSelector && endTime > startTime) ||
            (!useTimeSelector && (Double(hoursInput) ?? 0) > 0)
        )
    }
    
    // Calculate total hours for the day excluding the current effort
    private var totalHoursForSelectedDay: Double {
        let existingEfforts = sprintStore.effortsForDate(effort.date).filter { $0.id != effort.id }
        let existingHours = existingEfforts.reduce(0.0) { $0 + $1.hours }
        let newHours = useTimeSelector ? hoursFromTimeSelection : (Double(hoursInput) ?? 0)
        return existingHours + newHours
    }
    
    private var wouldExceedDailyLimit: Bool {
        totalHoursForSelectedDay > 24.0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(sprint.goals) { goal in
                        Button {
                            selectedGoalId = goal.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(goal.title)
                                        .foregroundColor(.primary)
                                    Text("Target: \(String(format: "%.1f", goal.targetHours)) hrs • Weight: \(Int(goal.weight * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedGoalId == goal.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Goal")
                }
                
                Section {
                    Toggle("Use time selector", isOn: $useTimeSelector)
                    
                    if useTimeSelector {
                        DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                        
                        HStack {
                            Text("Total hours:")
                            Spacer()
                            Text(String(format: "%.2f", hoursFromTimeSelection))
                                .fontWeight(.semibold)
                        }
                    } else {
                        HStack {
                            Text("Hours:")
                            TextField("e.g., 2.0", text: $hoursInput)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } header: {
                    Text("Time Spent")
                }
                
                Section {
                    TextField("Add any notes or details", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Notes (Optional)")
                }
                
                Section {
                    Button("Save Changes") {
                        saveUpdatedEffort()
                    }
                    .disabled(!canSave || wouldExceedDailyLimit)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor((canSave && !wouldExceedDailyLimit) ? .blue : .gray)
                    
                    if wouldExceedDailyLimit {
                        Text("Warning: Total effort for this day would exceed 24 hours (\(String(format: "%.1f", totalHoursForSelectedDay)) hrs)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    Button("Delete Effort") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Edit Effort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Effort", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    sprintStore.deleteEffort(effort)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this effort? This action cannot be undone.")
            }
        }
    }
    
    private func saveUpdatedEffort() {
        guard canSave, !wouldExceedDailyLimit else { return }
        
        let hours = useTimeSelector ? hoursFromTimeSelection : (Double(hoursInput) ?? 0)
        
        let updatedEffort = Effort(
            id: effort.id,
            goalId: selectedGoalId,
            date: effort.date,
            hours: hours
        )
        
        sprintStore.updateEffort(updatedEffort)
        dismiss()
    }
}

// View for showing all efforts with edit/delete capabilities
struct EffortListView: View {
    @EnvironmentObject var sprintStore: SprintStore
    @State private var showingEffortEditor = false
    @State private var selectedEffort: Effort? = nil
    @State private var searchText = ""
    @State private var filterBySprintName = ""
    @State private var filterByGoalName = ""
    @State private var sortOption: SortOption = .dateDesc
    
    // Sort options
    enum SortOption: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case hoursDesc = "Hours (High to Low)"
        case hoursAsc = "Hours (Low to High)"
        
        var comparator: (Effort, Effort) -> Bool {
            switch self {
            case .dateDesc:
                return { $0.date > $1.date }
            case .dateAsc:
                return { $0.date < $1.date }
            case .hoursDesc:
                return { $0.hours > $1.hours }
            case .hoursAsc:
                return { $0.hours < $1.hours }
            }
        }
    }
    
    // Filtered and sorted efforts
    private var filteredEfforts: [Effort] {
        var results = sprintStore.efforts
        
        // Apply search text filter if present
        if !searchText.isEmpty {
            results = results.filter { effort in
                // Check if date matches search
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let dateString = dateFormatter.string(from: effort.date)
                
                // Check if goal title or sprint name matches search
                let goalTitle = getGoalTitle(for: effort.goalId).lowercased()
                let sprintName = getSprintName(for: effort.goalId).lowercased()
                
                return dateString.lowercased().contains(searchText.lowercased()) ||
                       goalTitle.contains(searchText.lowercased()) ||
                       sprintName.contains(searchText.lowercased())
            }
        }
        
        // Apply sprint filter if selected
        if !filterBySprintName.isEmpty {
            results = results.filter { effort in
                getSprintName(for: effort.goalId) == filterBySprintName
            }
        }
        
        // Apply goal filter if selected
        if !filterByGoalName.isEmpty {
            results = results.filter { effort in
                getGoalTitle(for: effort.goalId) == filterByGoalName
            }
        }
        
        // Sort results
        return results.sorted(by: sortOption.comparator)
    }
    
    // Get unique sprint names for filtering
    private var uniqueSprintNames: [String] {
        var names = Set<String>()
        for effort in sprintStore.efforts {
            names.insert(getSprintName(for: effort.goalId))
        }
        return Array(names).sorted()
    }
    
    // Get unique goal names for filtering
    private var uniqueGoalNames: [String] {
        var names = Set<String>()
        for effort in sprintStore.efforts {
            names.insert(getGoalTitle(for: effort.goalId))
        }
        return Array(names).sorted()
    }
    
    var body: some View {
        List {
            // Search and filter section
            Section {
                // Search field
                TextField("Search by date, goal, or sprint", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Sprint filter
                Picker("Filter by Sprint:", selection: $filterBySprintName) {
                    Text("All Sprints").tag("")
                    ForEach(uniqueSprintNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                
                // Goal filter
                Picker("Filter by Goal:", selection: $filterByGoalName) {
                    Text("All Goals").tag("")
                    ForEach(uniqueGoalNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                
                // Sort option
                Picker("Sort by:", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Filters")
            }
            
            // Efforts list
            Section {
                if filteredEfforts.isEmpty {
                    Text("No matching efforts found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(filteredEfforts) { effort in
                        effortRow(for: effort)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEffort = effort
                                showingEffortEditor = true
                            }
                    }
                }
            } header: {
                Text("Efforts (\(filteredEfforts.count))")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Effort Management")
        .sheet(isPresented: $showingEffortEditor) {
            if let effort = selectedEffort,
               let sprint = sprintStore.getSprintForGoal(effort.goalId) {
                EditEffortView(effort: effort, sprint: sprint)
                    .environmentObject(sprintStore)
            }
        }
    }
    
    // Effort row display
    private func effortRow(for effort: Effort) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(getGoalTitle(for: effort.goalId))
                    .font(.headline)
                
                Text(getSprintName(for: effort.goalId))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(effort.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(effort.hours, specifier: "%.1f") hrs")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper to get the goal title for an effort
    private func getGoalTitle(for goalId: UUID) -> String {
        if let goal = sprintStore.getGoalById(goalId) {
            return goal.title
        }
        return "Unknown Goal"
    }
    
    // Helper to get the sprint name for a goal
    private func getSprintName(for goalId: UUID) -> String {
        if let sprint = sprintStore.getSprintForGoal(goalId) {
            return sprint.name
        }
        return "Unknown Sprint"
    }
}

// Helper to add effort editing functionality to SprintDetailView
struct EffortEditButton: View {
    let effort: Effort
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .foregroundColor(.blue)
        }
    }
}


extension SprintStore {
    static var mockForEffortEdit: SprintStore {
        let store = SprintStore()

        let goal = Goal(
            id: UUID(),
            title: "Study Swift",
            targetHours: 2,
            weight: 1
        )

        let sprint = Sprint(
            id: UUID(),
            name: "iOS Dev Sprint",
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            goals: [goal]
        )

        let effort = Effort(
            id: UUID(),
            goalId: goal.id,
            date: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            hours: 1.5
        )

        store.sprints = [sprint]
        store.efforts = [effort]

        return store
    }

    static var mockSprintForEffortEdit: Sprint {
        mockForEffortEdit.sprints.first!
    }

    static var mockEffort: Effort {
        mockForEffortEdit.efforts.first!
    }
}


#Preview {
    EditEffortView(
        effort: SprintStore.mockEffort,
        sprint: SprintStore.mockSprintForEffortEdit
    )
    .environmentObject(SprintStore.mockForEffortEdit)
}
