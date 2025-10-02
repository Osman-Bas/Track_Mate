//
//  Task.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//
import Foundation

struct TaskItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var date: Date
}
