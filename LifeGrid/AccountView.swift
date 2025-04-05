//  AccountView.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var sprintStore: SprintStore
    
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    @State private var navigateToSignup = false
    
    var body: some View {
        Form {
            
            // Sprint Management
            Section(header: Text("Progress & Analysis")) {
                NavigationLink("View Analytics", destination: TrendsNavigationView()
                    .environmentObject(sprintStore))
                
                
                

                NavigationLink("Sprint Timeline", destination: SprintGridTimelineView()
                    .environmentObject(userSettings)
                    .environmentObject(sprintStore))
            }
            
            // Data Management
            Section(header: Text("Data Management")) {

                
                NavigationLink("Manage Efforts", destination: EffortListView()
                    .environmentObject(sprintStore))
                
            
                NavigationLink("Manage Sprints", destination: SprintsView()
                    .environmentObject(sprintStore))
                
                
                Button("Delete All Data") {
                    showingDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            // Account Actions
            if userSettings.isLoggedIn {
                Section {
                    Button("Logout") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Account Settings")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(userSettings)
        }
        .navigationDestination(isPresented: $navigateToSignup) {
            SignupLoginView()
                .environmentObject(userSettings)
        }
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your sprints, efforts, and progress data. This action cannot be undone.")
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout? Your data will remain saved on this device.")
        }
    }
    
    // Function to export user data
    private func exportUserData() {
        // Implementation for exporting user data to JSON
        print("Exporting user data...")
    }
    
    // Function to import user data
    private func importUserData() {
        // Implementation for importing user data from JSON
        print("Importing user data...")
    }
    
    // Function to delete all user data
    private func deleteAllData() {
        // Clear all sprints and efforts
        sprintStore.sprints = []
        sprintStore.efforts = []
        
        // Save empty data to persistence
        sprintStore.saveSprints()
        sprintStore.saveEfforts()
        
        print("All data deleted")
    }
    
    // Function to handle logout
    private func logout() {
        userSettings.isLoggedIn = false
        userSettings.userName = "Guest"
        userSettings.userEmail = ""
        
        // Additional logout logic if needed
        print("User logged out")
    }
}

// Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: Int = 30
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                    Stepper("Age: \(age)", value: $age, in: 1...120)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load current values
                name = userSettings.userName
                email = userSettings.userEmail
                age = userSettings.currentAge
            }
        }
    }
    
    private func saveChanges() {
        userSettings.userName = name
        userSettings.userEmail = email
        userSettings.currentAge = age
        
        // Save settings to UserDefaults (implement in UserSettings class)
        userSettings.saveSettings()
    }
}

// Sign Up / Login View
struct SignupLoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var isSignUp = true
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var age: Int = 30
    @State private var targetAge: Int = 85
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("", selection: $isSignUp) {
                        Text("Sign Up").tag(true)
                        Text("Login").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                }
                
                if isSignUp {
                    // Sign Up Form
                    Section(header: Text("Create Account")) {
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                        
                        Stepper("Age: \(age)", value: $age, in: 1...120)
                        Stepper("Target Age: \(targetAge)", value: $targetAge, in: age...120)
                    }
                } else {
                    // Login Form
                    Section(header: Text("Login to Your Account")) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                }
                
                // Action Button
                Section {
                    Button(isSignUp ? "Sign Up" : "Login") {
                        if isSignUp {
                            signUp()
                        } else {
                            login()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Login")
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
    
    private func signUp() {
        // In a real app, this would validate and create a new account
        userSettings.isLoggedIn = true
        userSettings.userName = name
        userSettings.userEmail = email
        userSettings.currentAge = age
        userSettings.targetAge = targetAge
        userSettings.saveSettings()
        
        // Normally would connect to backend service
        print("User signed up: \(name)")
        dismiss()
    }
    
    private func login() {
        // In a real app, this would validate credentials with a backend
        // For now, we'll simulate a successful login
        userSettings.isLoggedIn = true
        userSettings.userName = "Test User" // Would normally come from backend
        userSettings.userEmail = email
        userSettings.saveSettings()
        
        print("User logged in: \(email)")
        dismiss()
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AccountView()
                .environmentObject(UserSettings())
                .environmentObject(SprintStore())
        }
    }
}
