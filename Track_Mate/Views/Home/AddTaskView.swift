
//  AddTaskView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

enum TaskPriority: String, CaseIterable, Identifiable {
    case low = "Düşük"
    case medium = "Orta"
    case high = "Yüksek"
    
    var id: String { self.rawValue }
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct AddTaskView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var time: Date = Date()
    @State private var priority: TaskPriority = .medium
    
    var body: some View {
        ZStack {
                   // MARK: - Arka Plan Blur
                   Color.black.opacity(0.4)
                       .ignoresSafeArea()
                   
                   VStack(spacing: 20) {
                       
                       // MARK: - Başlık
                       Text("Yeni Görev")
                           .font(.title.bold())
                           .foregroundColor(.white)
                           .padding(.top, 15)
                       
                       // MARK: - Kart Form
                       VStack(spacing: 15) {
                           
                           // Başlık
                           TextField("Başlık girin", text: $title)
                               .padding()
                               .background(.ultraThinMaterial)
                               .cornerRadius(12)
                           
                           // Açıklama (normal TextEditor, placeholder yok)
                           TextField("Açıklama", text: $description)
                               .padding(12)
                               .background(.ultraThinMaterial)
                               .cornerRadius(12)
                               .foregroundColor(.black)
                               .scrollContentBackground(.hidden)
                               .frame(minHeight: 60, maxHeight: 120)
                           
                       // Saat
                           DatePicker("Saat", selection: $time, displayedComponents: .hourAndMinute)
                               .labelsHidden()
                               .datePickerStyle(.wheel)
                               .frame(maxHeight: 120)
                               .padding()
                               .background(.ultraThinMaterial)
                               .cornerRadius(12)
                           
                           // Öncelik
                           Picker("Öncelik", selection: $priority) {
                               ForEach(TaskPriority.allCases) { pr in
                                   Text(pr.rawValue)
                                       .tag(pr)
                               }
                           }
                           .pickerStyle(.segmented)
                           .padding(.vertical, 5)
                       }
                       .padding()
                       .background(Color.white.opacity(0.08))
                       .cornerRadius(20)
                       .shadow(radius: 5)
                       .padding(.horizontal)
                       
                       // MARK: - Butonlar
                       HStack(spacing: 15) {
                           Button(action: {
                               dismiss()
                           }) {
                               Text("İptal")
                                   .fontWeight(.bold)
                                   .frame(maxWidth: .infinity)
                                   .padding()
                                   .background(Color.red.opacity(0.9))
                                   .foregroundColor(.white)
                                   .cornerRadius(15)
                           }
                           
                           Button(action: {
                               let newTask = TaskItem(title: title, isCompleted: false, date: time)
                               taskVM.tasks.append(newTask)
                               dismiss()
                           }) {
                               Text("Kaydet")
                                   .fontWeight(.bold)
                                   .frame(maxWidth: .infinity)
                                   .padding()
                                   .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.6) : Color.green)
                                   .foregroundColor(.white)
                                   .cornerRadius(15)
                           }
                           .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                       }
                       .padding(.horizontal)
                       .padding(.bottom, 20)
                       
                       Spacer()
                   }
                   .padding(.top, 60) // Üstten biraz yukarı kaydırdık
               }
           }
}

// MARK: - Preview
struct ModernAddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let taskVM = TaskViewModel()
        AddTaskView()
            .environmentObject(taskVM)
            .previewDevice("iPhone 14 Pro")
    }
}
