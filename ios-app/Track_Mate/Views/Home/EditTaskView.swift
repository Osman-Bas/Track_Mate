//
//  EditTaskView.swift
//  Track_Mate
//
//  Created by Osman Baş on 7.10.2025.
//

import SwiftUI

struct EditTaskView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var task: TaskItem
    
    // 🎯 Banner tetikleme callback
    var onSave: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 120, height: 5)
                    .shadow(color: .white, radius: 4, x: 0, y: 2)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                Text("Görevi Düzenle")
                    .font(.title.bold())
                    .foregroundColor(.black)
                    .padding(.top,60)
                    .padding(.bottom,10)
                
                // MARK: - Form
                VStack(spacing: 12) {
                    TextField("Başlık", text: $task.title)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    
                    TextField("Açıklama", text: $task.description)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .frame(minHeight: 60, maxHeight: 120)
                    
                    DatePicker("Saat", selection: $task.date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .frame(maxHeight: 120)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    
                    // Öncelik seçimi
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Öncelik")
                            .foregroundColor(.black.opacity(0.7))
                            .font(.headline)
                        
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases) { pr in
                                Text(pr.rawValue)
                                    .fontWeight(task.priority == pr ? .bold : .regular)
                                    .foregroundColor(task.priority == pr ? .black : .black.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            if task.priority == pr {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(pr.color.opacity(0.3))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(pr.color, lineWidth: 1.5)
                                                    )
                                                    .shadow(color: pr.color.opacity(0.6), radius: 8)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.ultraThinMaterial)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            task.priority = pr
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
                    Button("İptal") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .foregroundColor(.black)
                    .cornerRadius(15)
                    
                    Button("Kaydet") {
                        // 1. ViewModel'deki yeni 'updateTask' fonksiyonunu çağır
                        taskVM.updateTask(task: task)
                        
                        // 2. Banner'ı tetikle
                        onSave?()
                        
                        // 3. Ekranı kapat
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

// MARK: - Preview
struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let taskVM = TaskViewModel()
        EditTaskView(task: TaskItem(title: "Test Görev", description: "Bu bir test açıklamasıdır.", isCompleted: false, date: Date(), priority: .medium), onSave: {
            print("Görev düzenlendi banner tetiklendi!")
        })
        .environmentObject(taskVM)
        .previewDevice("iPhone 15")
    }
}
