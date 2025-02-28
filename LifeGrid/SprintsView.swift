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
    @State private var goals: [Goal] = []  // Later, add UI to create/edit goals.
    
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
                    // Placeholder – add UI to create goals as needed.
                    Text("Add goals here later")
                        .foregroundColor(.gray)
                }
                Button("Save") {
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
        }
    }
}

struct SprintsView_Previews: PreviewProvider {
    static var previews: some View {
        SprintsView()
    }
}
