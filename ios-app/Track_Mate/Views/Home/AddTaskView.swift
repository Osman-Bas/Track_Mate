//  AddTaskView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

enum TaskPriority: String, CaseIterable, Identifiable, Codable {
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
    
    // 🎯 Banner tetikleme callback'i
    var onSave: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color("pembe")
                .opacity(0.4)
                
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Capsule()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 120, height: 5)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                Text("Yeni Görev")
                    .font(.title.bold())
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.top,60)
                    .padding(.bottom,10)
                
                VStack(spacing: 12) {
                    TextField("Başlık girin", text: $title)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    
                    TextField("Açıklama", text: $description)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 60, maxHeight: 120)
                    
                    DatePicker("Saat", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .frame(maxHeight: 120)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                    
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases) { pr in
                                Text(pr.rawValue)
                                    .fontWeight(priority == pr ? .bold : .regular)
                                    .foregroundColor(priority == pr ? .white : .black.opacity(0.7))
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
                    .padding(.top, 20)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("İptal")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("pembe"))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        // ViewModel'deki yeni fonksiyonu çağır
                                                taskVM.addTask(title: title,
                                                             description: description,
                                                             date: time,
                                                             priority: priority)
                                                
                                                onSave?() // Banner'ı göster
                                                dismiss() // Ekranı kapat
                        
                        // 🎯 Banner callback
                        onSave?()
                        
                        dismiss()
                    }) {
                        Text("Kaydet")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color("yesil") : Color("koyuyesil").opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
struct ModernAddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let taskVM = TaskViewModel()
        AddTaskView(onSave: {
            print("Görev eklendi banner tetiklendi!")
        })
        .environmentObject(taskVM)
        .previewDevice("iPhone 15")
    }
}
