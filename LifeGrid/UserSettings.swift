//
//  UserSettings.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    // Published properties will cause views to update when changed
    @Published var isFirstLaunch: Bool
    @Published var currentAge: Int
    @Published var targetAge: Int
    @Published var yearsToView: Int
    
    // New user account properties
    @Published var isLoggedIn: Bool
    @Published var userName: String
    @Published var userEmail: String
    
    init() {
        // Check if the app has been launched before
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.isFirstLaunch = !hasLaunchedBefore
        
        // Load user's age or set default
        let savedAge = UserDefaults.standard.integer(forKey: "currentAge")
        self.currentAge = savedAge > 0 ? savedAge : 30 // Default age
        
        // Load target age or set default
        let savedTargetAge = UserDefaults.standard.integer(forKey: "targetAge")
        self.targetAge = savedTargetAge > 0 ? savedTargetAge : 85 // Default target age
        
        // Load years to view setting or set default
        let savedYearsToView = UserDefaults.standard.integer(forKey: "yearsToView")
        self.yearsToView = savedYearsToView > 0 ? savedYearsToView : 5 // Default years to view
        
        // Load user account information
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Guest"
        self.userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        
        // Set up observation for properties to save changes
        setupObservers()
    }
    
    // Set up observers for each published property
    private func setupObservers() {
        $isFirstLaunch
            .sink { [weak self] newValue in
                UserDefaults.standard.set(!newValue, forKey: "hasLaunchedBefore")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $currentAge
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: "currentAge")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $targetAge
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: "targetAge")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $yearsToView
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: "yearsToView")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $isLoggedIn
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: "isLoggedIn")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $userName
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: "userName")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $userEmail
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: "userEmail")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // Store cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // Save all settings to UserDefaults
    func saveSettings() {
        UserDefaults.standard.set(!isFirstLaunch, forKey: "hasLaunchedBefore")
        UserDefaults.standard.set(currentAge, forKey: "currentAge")
        UserDefaults.standard.set(targetAge, forKey: "targetAge")
        UserDefaults.standard.set(yearsToView, forKey: "yearsToView")
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(userEmail, forKey: "userEmail")
    }
    
    // Reset user account (logout)
    func resetUserAccount() {
        isLoggedIn = false
        userName = "Guest"
        userEmail = ""
        saveSettings()
    }
}
