//
//  JournalEntry.swift
//  Track_Mate
//
//  Created by Osman Baş on 17.11.2025.
//

import Foundation

struct JournalEntry: Identifiable, Codable, Hashable {
    var id: String?
    var mood: String
    var journal: String
    var createdAt: String // Tarihi String olarak alacağız (şimdilik)
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mood, journal, createdAt
    }
}
