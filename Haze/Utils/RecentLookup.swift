//
//  RecentLookup.swift
//  Haze
//
//  Created by Ben on 13/07/2026.
//


import Foundation

struct RecentLookup: Codable, Identifiable {
    let id: UUID
    let ip: String
    let country: String
    let organisation: String
    let timestamp: Date
}
