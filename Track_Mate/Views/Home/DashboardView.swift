//
//  DashboardView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showAddTask = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Profil ve Karşılama
                    if let user = userVM.currentUser {
                        HStack(alignment: .center, spacing: 15) {
                            Image(systemName: user.profileImage ?? "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                            
                            Text("Merhaba, \(user.username)")
                                .font(.title2.bold())
                        }
                        .padding(.horizontal)
                    }
                    
                    Text("Bugünkü Görevler")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // MARK: - Görev Listesi
                    if taskVM.tasks.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("Bugün görev yok 🎉")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(taskVM.tasks) { task in
                                    TaskCard(task: task)
                                        .onTapGesture {
                                            taskVM.toggleTaskCompletion(task: task)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // MARK: - Floating "+" Butonu
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                        .sheet(isPresented: $showAddTask) {
                            AddTaskView()
                                .environmentObject(taskVM)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Görev Kartı Bileşeni
struct TaskCard: View {
    var task: TaskItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body.bold())
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                Text(task.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}
// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let userVM = UserViewModel()
        userVM.login(username: "Osman", email: "osman@example.com")
        
        let taskVM = TaskViewModel()
        taskVM.addTask(title: "SwiftUI ödevi yap")
        taskVM.addTask(title: "TrackMate tasarımını güncelle")
        taskVM.addTask(title: "Yeni görev ekle")
        
        return DashboardView()
            .environmentObject(userVM)
            .environmentObject(taskVM)
            .previewDevice("iPhone 15")
    }
}
