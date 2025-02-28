//
//  DataPersistence.swift
//  LifeGrid
//
//  Created on 2/27/25.
//

import Foundation
import Combine

class DataPersistence {
    static let shared = DataPersistence()
    
    private let sprintsKey = "user_sprints"
    private let effortsKey = "user_efforts"
    
    // Save sprints to UserDefaults
    func saveSprints(_ sprints: [Sprint]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(sprints)
            UserDefaults.standard.set(data, forKey: sprintsKey)
        } catch {
            print("Failed to save sprints: \(error.localizedDescription)")
        }
    }
    
    // Load sprints from UserDefaults
    func loadSprints() -> [Sprint] {
        guard let data = UserDefaults.standard.data(forKey: sprintsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Sprint].self, from: data)
        } catch {
            print("Failed to load sprints: \(error.localizedDescription)")
            return []
        }
    }
    
    // Save efforts to UserDefaults
    func saveEfforts(_ efforts: [Effort]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(efforts)
            UserDefaults.standard.set(data, forKey: effortsKey)
        } catch {
            print("Failed to save efforts: \(error.localizedDescription)")
        }
    }
    
    // Load efforts from UserDefaults
    func loadEfforts() -> [Effort] {
        guard let data = UserDefaults.standard.data(forKey: effortsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Effort].self, from: data)
        } catch {
            print("Failed to load efforts: \(error.localizedDescription)")
            return []
        }
    }
    
    // Save efforts for a specific sprint
    func saveEffortsForSprint(sprintId: UUID, efforts: [Effort]) {
        let key = "efforts_for_sprint_\(sprintId.uuidString)"
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(efforts)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save efforts for sprint: \(error.localizedDescription)")
        }
    }
    
    // Load efforts for a specific sprint
    func loadEffortsForSprint(sprintId: UUID) -> [Effort] {
        let key = "efforts_for_sprint_\(sprintId.uuidString)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Effort].self, from: data)
        } catch {
            print("Failed to load efforts for sprint: \(error.localizedDescription)")
            return []
        }
    }
}
