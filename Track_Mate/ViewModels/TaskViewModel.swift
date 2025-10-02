//
//  TaskViewModel.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//
import SwiftUI
internal import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    func addTask(title: String) {
        let newTask = TaskItem(title: title, isCompleted: false, date: Date())
        tasks.append(newTask)
    }
    
    func toggleTaskCompletion(task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
}
