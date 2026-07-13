//
//  RecentsManager.swift
//  Haze
//
//  Created by Ben on 13/07/2026.
//


import Foundation

class RecentsManager: ObservableObject {
    @Published var recents: [RecentLookup] = []

    private let key = "recentLookups"

    init() {
        load()
    }

    func add(_ lookup: RecentLookup) {
        // Remove duplicate IPs
        recents.removeAll { $0.ip == lookup.ip }

        // Add newest at the top
        recents.insert(lookup, at: 0)

        // Keep only last 10
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }

        save()
    }
    
    func remove(_ recent: RecentLookup) {
        recents.removeAll { $0.id == recent.id }
        save()
    }

    func removeAll() {
        recents.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([RecentLookup].self, from: data)
        else {
            return
        }

        recents = saved
    }
}
