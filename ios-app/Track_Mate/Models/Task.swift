//
//  Task.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//
import Foundation

struct TaskItem: Identifiable, Codable, Equatable{
    var id: String?
    var title: String
    var description: String = ""
    var isCompleted: Bool
    var date: Date
    var priority: TaskPriority = .medium
    
    // JSON'daki isimleri Swift'teki isimlerle eşleştirir
    enum CodingKeys: String, CodingKey {
        case id = "_id" // JSON'daki "_id"yi, struct'ımızdaki "id"ye ata
        case title
        case description
        case isCompleted
        case date
        case priority
    }

}
