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
                // MARK: - Capsule
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 120, height: 5)
                    .shadow(color: Color.white, radius: 4, x: 0, y: 2)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                // MARK: - Başlık
                Text("Yeni Görev")
                    .font(.title.bold())
                    .foregroundColor(.black)
                    .padding(.top,60)
                    .padding(.bottom,10)
                
                // MARK: - Kart Form
                VStack(spacing: 12) {
                    // Başlık
                    TextField("Başlık girin", text: $title)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    
                    // Açıklama
                    TextField("Açıklama", text: $description)
                        .padding()
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Öncelik")
                            .foregroundColor(.black.opacity(0.7))
                            .font(.headline)
                        
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases) { pr in
                                Text(pr.rawValue)
                                    .fontWeight(priority == pr ? .bold : .regular)
                                    .foregroundColor(priority == pr ? .black : .black.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            if priority == pr {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(pr.color.opacity(0.3))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(pr.color, lineWidth: 1.5)
                                                    )
                                                    .shadow(color: pr.color.opacity(0.6), radius: 8)
                                                    .transition(.scale)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.ultraThinMaterial)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            priority = pr
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                // MARK: - Butonlar
                HStack(spacing: 20) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("İptal")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.black)
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
                            .foregroundColor(.black)
                            .cornerRadius(15)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top) // VStack'i üstte hizala
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
