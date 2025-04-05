//
//  UserSettings.swift
//  LifeGrid
//  (Modified to remove age-based calculations)
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    // Published properties will cause views to update when changed
    @Published var isFirstLaunch: Bool
    @Published var currentAge: Int = 30 // Retained for compatibility
    @Published var targetAge: Int = 85  // Retained for compatibility
    @Published var yearsToView: Int // Kept for displaying data in timeline view
    
    // User account properties
    @Published var isLoggedIn: Bool
    @Published var userName: String
    @Published var userEmail: String
    
    // Preferences
    @Published var defaultGridView: GridViewType
    
    // Grid view types
    enum GridViewType: String, Codable {
        case daily
        case weekly
        case monthly
    }
    
    init() {
        // Check if the app has been launched before
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.isFirstLaunch = !hasLaunchedBefore
        
        // Load user's age or set default (keeping for compatibility)
        let savedAge = UserDefaults.standard.integer(forKey: "currentAge")
        self.currentAge = savedAge > 0 ? savedAge : 30 // Default age
        
        // Load target age or set default (keeping for compatibility)
        let savedTargetAge = UserDefaults.standard.integer(forKey: "targetAge")
        self.targetAge = savedTargetAge > 0 ? savedTargetAge : 85 // Default target age
        
        // Load years to view setting or set default
        let savedYearsToView = UserDefaults.standard.integer(forKey: "yearsToView")
        self.yearsToView = savedYearsToView > 0 ? savedYearsToView : 5 // Default years to view
        
        // Load user account information
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Guest"
        self.userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        
        // Load preferences or set defaults
        if let gridViewTypeStr = UserDefaults.standard.string(forKey: "defaultGridView"),
           let gridViewType = GridViewType(rawValue: gridViewTypeStr) {
            self.defaultGridView = gridViewType
        } else {
            self.defaultGridView = .daily // Default view type
        }
        
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
        
        $defaultGridView
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: "defaultGridView")
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
        UserDefaults.standard.set(defaultGridView.rawValue, forKey: "defaultGridView")
    }
    
    // Reset user account (logout)
    func resetUserAccount() {
        isLoggedIn = false
        userName = "Guest"
        userEmail = ""
        saveSettings()
    }
    
    // IMPORTANT: Keeping only one mock method for previews
    // We're keeping the existing mock methods in the original file
    // and removing our new declaration to avoid the duplicate error
}
