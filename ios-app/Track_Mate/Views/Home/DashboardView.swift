//
//  DashboardView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI
import AVFoundation

struct DashboardView: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showAddTask = false
    @State private var selectedTask: TaskItem? = nil
//    @State private var showEditTask = false
    @State private var showSuccessBanner = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // MARK: - Success Banner
                if showSuccessBanner {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                            Text(successMessage)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .cornerRadius(14)
                        .shadow(radius: 6)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .animation(.spring(), value: showSuccessBanner)
                    .zIndex(1)
                    .onAppear {
                        AudioServicesPlaySystemSound(1022)
                    }
                }
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Profil ve Karşılama
                    if let user = userVM.currentUser {
                        HStack(alignment: .center, spacing: 15) {
                            if let user = userVM.currentUser {
                                HStack(alignment: .center, spacing: 15) {
                                    if let urlString = user.profilePictureUrl,
                                       !urlString.isEmpty,
                                       let url = URL(string: urlString) {
                                        
                                        // 2. URL VARSA: İnternetten indirmek için AsyncImage kullan
                                        AsyncImage(url: url) { image in
                                            // Resim yüklendiğinde
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            // Resim yüklenirken
                                            ProgressView() // Dönen bir yükleme ikonu göster
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                        
                                    } else {
                                        // 3. URL YOKSA: Varsayılan (default) ikonu kullan
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .shadow(radius: 4)
                                    }
                                }
                            }
                            Text("Merhaba, \(user.username)")
                                .font(.title2.bold())
                        }
                        .padding(.horizontal)
                    }
                    
                    Text("Bugünkü Görevler")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // MARK: - Görev Listesi
                    if taskVM.isLoading {
                        // 1. Durum: Yükleniyor
                        // Görevler çekilirken dönen bir çember göster
                        Spacer() // Boşluğu doldurmak için
                        ProgressView() // Dönen yükleme çemberi
                        Spacer()
                        
                    } else if taskVM.tasks.isEmpty {
                        // 2. Durum: Yükleme bitti VE görev yok
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("Bugün görev yok 🎉")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Spacer()
                        
                    } else {
                        // 3. Durum: Yükleme bitti VE görevler var
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(taskVM.tasks) { task in
                                    TaskCard(task: task)
                                        .contextMenu {
                                            Button {
                                                selectedTask = task
//                                                showEditTask = true
                                            } label: {
                                                Label("Görevi Düzenle", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive) {
                                                taskVM.deleteTask(task: task)
                                            } label: {
                                                Label("Görevi Sil", systemImage: "trash")
                                            }
                                        }
                                        .onTapGesture {
                                            taskVM.toggleTaskCompletion(task: task)
                                        }
                                }
                                
                            }
                            .padding(.horizontal)
                        }
                        .sheet(item: $selectedTask) { task in
                                                // 'item' kullandığımız için 'if let'e gerek yok.
                                                // 'task' zaten dolu olarak gelir.
                                                EditTaskView(task: task, onSave: {
                                                    showBanner(message: "Görev güncellendi ✏️")
                                                })
                                                .environmentObject(taskVM)
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
                            AddTaskView(onSave: {
                                showBanner(message: "Görev eklendi 🎉")
                            })
                            .environmentObject(taskVM)
                        }
                    }
                }
            }
        }
        .onAppear { // <-- BU BLOĞU EKLE
            print("DashboardView göründü, görevler çekiliyor...")
            taskVM.fetchTasks()
        }
    }
    
    // MARK: - Banner gösterme fonksiyonu
    func showBanner(message: String) {
        successMessage = message
        withAnimation {
            showSuccessBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccessBanner = false
            }
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Görev Kartı
struct TaskCard: View {
    var task: TaskItem
    @State private var animateComplete = false
    @State private var glow = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(task.isCompleted ? .white.opacity(0.6) : .white)
                    .strikethrough(task.isCompleted, color: .white.opacity(0.6))
                    .italic(task.isCompleted)
                    .shadow(color: glow ? Color.white.opacity(0.8) : .clear, radius: glow ? 10 : 0)
                    .scaleEffect(glow ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: glow)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Text(task.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .scaleEffect(glow ? 1.3 : 1.0)
                    .shadow(color: glow ? .green.opacity(0.8) : .clear, radius: glow ? 15 : 0)
                    .onAppear {
                        playSuccessSound()
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                            glow = true
                            animateComplete = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                glow = false
                                animateComplete = false
                            }
                        }
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: vibrantGradient(for: task.priority),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(22)
        .shadow(color: vibrantGradient(for: task.priority).first!.opacity(0.4),
                radius: 10, x: 0, y: 6)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: task.isCompleted)
        .padding(.horizontal, 6)
    }
    
    func playSuccessSound() {
        AudioServicesPlaySystemSound(1166)
    }
    
    func vibrantGradient(for priority: TaskPriority) -> [Color] {
        switch priority {
        case .high:
            return [Color(red: 0.93, green: 0.32, blue: 0.37),
                    Color(red: 0.85, green: 0.15, blue: 0.47)]
        case .medium:
            return [Color(red: 0.98, green: 0.67, blue: 0.24),
                    Color(red: 0.94, green: 0.48, blue: 0.15)]
        case .low:
            return [Color(red: 0.29, green: 0.78, blue: 0.52),
                    Color(red: 0.13, green: 0.68, blue: 0.74)]
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        
        // --- 1. Sahte UserViewModel Hazırla ---
        let userVM = UserViewModel()
        
        // Düzeltme: Artık login() çağırmıyoruz.
        // Onun yerine, modele uygun sahte bir kullanıcı yaratıp
        // 'currentUser' değişkenine manuel olarak atıyoruz.
        userVM.currentUser = User(
            id: "previewUser123", // Yeni modelimize uygun sahte bir 'id'
            fullName: "Osman Baş", // Yeni modelimize uygun 'fullName'
            username: "Osman",
            email: "osman@example.com",
            profilePictureUrl: "person.circle.fill" // İsim 'profilePictureUrl' olarak değişmişti
        )
        userVM.isLoggedIn = true // Giriş yapmış gibi davran
        
        
        // --- 2. Sahte TaskViewModel Hazırla ---
        let taskVM = TaskViewModel()
        
        // Düzeltme: TaskItem modelimiz 'id: String?' olarak değiştiği için
        // önizleme verisine de sahte 'id'ler ekleyelim.
        taskVM.tasks = [
            TaskItem(
                id: "task1", // <-- YENİ
                title: "SwiftUI ödevi yap",
                description: "Ders için SwiftUI ödevini tamamla ve projeyi GitHub'a yükle.",
                isCompleted: false,
                date: Date(),
                priority: .high
            ),
            TaskItem(
                id: "task2", // <-- YENİ
                title: "TrackMate tasarımını güncelle",
                description: "Görev kartlarını ve renkleri güncelle, yeni animasyonları ekle.",
                isCompleted: false,
                date: Date(),
                priority: .medium
            ),
            TaskItem(
                id: "task3", // <-- YENİ
                title: "Yeni görev ekle",
                description: "Kullanıcıdan yeni görev ekleme formunu test et ve hata varsa düzelt.",
                isCompleted: false,
                date: Date(),
                priority: .low
            )
        ]
        
        
        // --- 3. Görünümü Geri Döndür ---
        return DashboardView()
            .environmentObject(userVM)
            .environmentObject(taskVM)
            .previewDevice("iPhone 15")
    }
}
