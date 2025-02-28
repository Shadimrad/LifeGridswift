//
//  DatePickerEffortLoggingView.swift
//  LifeGrid
//
//  Created on 2/28/25.
//

import SwiftUI

struct DatePickerEffortLoggingView: View {
    let sprint: Sprint
    
    @State private var selectedDate: Date
    @State private var selectedGoalId: UUID?
    @State private var hoursInput: String = ""
    @State private var useTimeSelector = false
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600) // One hour later by default
    @State private var notes: String = ""
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sprintStore: SprintStore
    
    // Initialize with the current date by default, but allow passing a specific date
    init(sprint: Sprint, initialDate: Date = Date()) {
        self.sprint = sprint
        _selectedDate = State(initialValue: initialDate)
    }
    
    // Calculate valid date range for the sprint
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: sprint.startDate)
        let endDate = calendar.startOfDay(for: sprint.endDate)
        return startDate...endDate
    }
    
    // Determine if effort can be saved
    private var canSave: Bool {
        selectedGoalId != nil && (
            (useTimeSelector && endTime > startTime) ||
            (!useTimeSelector && (Double(hoursInput) ?? 0) > 0)
        )
    }
    
    // Calculate hours from time selection
    private var hoursFromTimeSelection: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: startTime, to: endTime)
        let minutes = components.minute ?? 0
        return Double(minutes) / 60.0
    }
    
    // Get efforts logged for the selected date
    private var dayEfforts: [Effort] {
        sprintStore.effortsForDate(selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Date selection section
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: dateRange,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Select Date")
                }
                
                // Goal selection section
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
                
                // Hours input section
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
                
                // Optional notes
                Section {
                    TextField("Add any notes or details", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Notes (Optional)")
                }
                
                // Today's logged efforts section
                if !dayEfforts.isEmpty {
                    Section {
                        ForEach(dayEfforts) { effort in
                            let goalTitle = getGoalTitle(for: effort.goalId)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(goalTitle)
                                    
                                    if Calendar.current.isDateInToday(selectedDate) {
                                        Text("Logged at \(effort.date, style: .time)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", effort.hours)) hrs")
                                    .fontWeight(.semibold)
                            }
                        }
                    } header: {
                        if Calendar.current.isDateInToday(selectedDate) {
                            Text("Already Logged Today")
                        } else {
                            Text("Already Logged for \(selectedDate, style: .date)")
                        }
                    }
                }
                
                // Save button
                Section {
                    Button(action: saveEffort) {
                        HStack {
                            Spacer()
                            Text("Save Effort")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Log Effort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Save the effort
    private func saveEffort() {
        guard let goalId = selectedGoalId else { return }
        
        let hours = useTimeSelector ? hoursFromTimeSelection : (Double(hoursInput) ?? 0)
        guard hours > 0 else { return }
        
        // Create a new effort
        let effort = Effort(
            goalId: goalId,
            date: selectedDate, // Use the selected date
            hours: hours
        )
        
        // Add effort to the store
        sprintStore.addEffort(effort)
        
        // Dismiss the sheet
        dismiss()
    }
    
    // Helper to get the goal title for an effort
    private func getGoalTitle(for goalId: UUID) -> String {
        if let goal = sprint.goals.first(where: { $0.id == goalId }) {
            return goal.title
        }
        return "Unknown Goal"
    }
}

struct DatePickerEffortLoggingView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSprint = Sprint(
            name: "Sample Sprint",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            goals: [
                Goal(title: "Study", targetHours: 2.0, weight: 0.5),
                Goal(title: "Exercise", targetHours: 1.0, weight: 0.3)
            ]
        )
        
        return DatePickerEffortLoggingView(sprint: sampleSprint)
            .environmentObject(SprintStore())
    }
}
