//
//  UserSettings.swift
//  LifeGrid
//
//  Created by shaqayeq Rad on 2/26/25.
//
import SwiftUI
// MARK: UserSettings
// This class stores user preferences and persists them using UserDefaults.
// Because it conforms to ObservableObject, any changes will update all views that use it.
import SwiftUI

class UserSettings: ObservableObject {
    @Published var currentAge: Int {
        didSet { UserDefaults.standard.set(currentAge, forKey: "currentAge") }
    }
    @Published var targetAge: Int {
        didSet { UserDefaults.standard.set(targetAge, forKey: "targetAge") }
    }
    @Published var isFirstLaunch: Bool {
        didSet { UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch") }
    }
    
    // Read-write computed property: calculated as (targetAge - currentAge)
    var yearsToView: Int {
        get { max(targetAge - currentAge, 0) }
        set { targetAge = currentAge + newValue }
    }
    
    init() {
        self.currentAge = UserDefaults.standard.integer(forKey: "currentAge")
        self.targetAge = UserDefaults.standard.integer(forKey: "targetAge")
        self.isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool ?? true
    }
}

