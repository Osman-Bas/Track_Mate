//
//  TaskViewModel.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI
internal import Combine

class TaskViewModel: ObservableObject {
    
    // Gerçek görevleri tutacak liste (Başlangıçta boş)
    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = false
    
    // API Ana Adresi (UserViewModel ile aynı)
    private let apiBaseURL = "http://192.168.8.164:3000/api/tasks"
    
    // MARK: - 1. GÖREVLERİ GETİR (GET /api/tasks)
    func fetchTasks() {
        guard let token = KeychainService.readToken() else {
            print("TaskVM: Token yok, görevler getirilemedi.")
            return
        }
        
        guard let url = URL(string: apiBaseURL) else { return }
        
        // ---- YENİ ADIM 1 ----
        // Ağ isteği başlamadan hemen önce "Yükleniyor" durumunu aç
        DispatchQueue.main.async {
            self.isLoading = true
        }
        // ---- YENİ ADIM SONU ----

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // ---- YENİ ADIM 2 ----
            // İstek bittiğinde, (başarılı da olsa hata da olsa)
            // "Yükleniyor" durumunu ana thread'de kapat
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            // ---- YENİ ADIM SONU ----

            if let error = error {
                print("TaskVM Fetch Hatası: \(error.localizedDescription)")
                // TODO: userVM'dekine benzer bir errorMessage değişkeni ekle
                return
            }
            
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let fetchedTasks = try decoder.decode([TaskItem].self, from: data)
                    self.tasks = fetchedTasks
                    print("TaskVM: \(fetchedTasks.count) görev başarıyla getirildi.")
                    
                } catch {
                    print("TaskVM JSON Decode Hatası: \(error)")
                }
            }
        }.resume()
    }
    
    // MARK: - 2. YENİ GÖREV EKLE (POST /api/tasks)
    func addTask(title: String, description: String, date: Date, priority: TaskPriority) {
        guard let token = KeychainService.readToken() else { return }
        guard let url = URL(string: apiBaseURL) else { return }
        
        // Gönderilecek veriyi hazırla
        // (Tarihi backend'in anladığı ISO8601 string formatına çeviriyoruz)
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = isoDateFormatter.string(from: date)

        let body: [String: Any] = [
            "title": title,
            "description": description,
            "date": dateString,
            "priority": priority.rawValue // "High", "Medium" vb. string değeri
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                print("TaskVM Ekleme Hatası (Sunucu)")
                return
            }
            
            // Başarılı olursa, listeyi sunucudan tekrar çekip güncelle
            print("TaskVM: Görev başarıyla eklendi.")
            DispatchQueue.main.async {
                self.fetchTasks()
            }
        }.resume()
    }
    
    // MARK: - 3. GÖREV DURUMUNU DEĞİŞTİR (PATCH /api/tasks/:id/toggle)
    func toggleTaskCompletion(task: TaskItem) {
        guard let id = task.id, let token = KeychainService.readToken() else { return }
        
        let urlString = "\(apiBaseURL)/\(id)/toggle"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Optimistik UI Güncellemesi:
        // Sunucudan cevap gelmesini beklemeden, UI'da hemen değiştir (hız hissi için)
        if let index = self.tasks.firstIndex(where: { $0.id == id }) {
            DispatchQueue.main.async {
                self.tasks[index].isCompleted.toggle()
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // Eğer sunucuda hata olursa, değişikliği geri al (rollback)
                print("TaskVM Toggle Hatası! Değişiklik geri alınıyor.")
                DispatchQueue.main.async {
                    self.fetchTasks() // En garantisi listeyi yeniden çekmektir
                }
            }
        }.resume()
    }
    // MARK: - 4. BİR GÖREVİ SİL (DELETE /api/tasks/:id)
        func deleteTask(task: TaskItem) {
            
            // 1. Silinecek görevin ID'si ve token var mı?
            guard let id = task.id, let token = KeychainService.readToken() else {
                print("TaskVM: Token veya Görev ID'si yok, silinemedi.")
                return
            }
            
            // 2. Adresi oluştur: .../api/tasks/12345
            let urlString = "\(apiBaseURL)/\(id)"
            guard let url = URL(string: urlString) else {
                print("TaskVM: Geçersiz silme URL'i")
                return
            }
            
            // 3. İsteği hazırla
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // 4. (Opsiyonel ama Önerilir) Optimistik UI:
            //    Sunucudan cevap beklemeden görevi UI'dan hemen kaldır.
            //    Bu, uygulamanın "hızlı" hissettirmesini sağlar.
            DispatchQueue.main.async {
                self.tasks.removeAll(where: { $0.id == id })
            }
            
            // 5. İsteği gönder
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("TaskVM Silme Hatası (Ağ): \(error.localizedDescription)")
                    // Hata olursa, listeyi sunucudan geri yükle (rollback)
                    DispatchQueue.main.async { self.fetchTasks() }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                
                // Sude'nin kodu başarı durumunda 200 kodu gönderiyor
                if httpResponse.statusCode == 200 {
                    print("TaskVM: Görev ID \(id) sunucudan başarıyla silindi.")
                    // Not: 'fetchTasks()'i tekrar çağırmaya gerek yok,
                    // çünkü "Optimistik UI" ile zaten sildik.
                } else {
                    print("TaskVM Silme Hatası (Sunucu): Kod \(httpResponse.statusCode)")
                    // Hata olursa, listeyi sunucudan geri yükle (rollback)
                    DispatchQueue.main.async { self.fetchTasks() }
                }
            }.resume()
        }
    // MARK: - 5. BİR GÖREVİ GÜNCELLE (PUT /api/tasks/:id)
        func updateTask(task: TaskItem) {
            
            // 1. Güncellenecek görevin ID'si ve token var mı?
            guard let id = task.id, let token = KeychainService.readToken() else {
                print("TaskVM: Token veya Görev ID'si yok, güncellenemedi.")
                return
            }
            
            // 2. Adresi oluştur: .../api/tasks/12345
            let urlString = "\(apiBaseURL)/\(id)"
            guard let url = URL(string: urlString) else {
                print("TaskVM: Geçersiz güncelleme URL'i")
                return
            }
            
            // 3. İsteği hazırla
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // 4. Gidecek JSON Verisini Hazırla (Codable kullanarak)
            //    Tarih formatlaması için bir encoder kullanalım
            do {
                let encoder = JSONEncoder()
                // Backend'in 'date' alanını (ISO8601) anlayabilmesi için:
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                encoder.dateEncodingStrategy = .custom({ date, encoder in
                    var container = encoder.singleValueContainer()
                    let dateString = isoFormatter.string(from: date)
                    try container.encode(dateString)
                })
                
                // TaskItem objesini (güncellenmiş haliyle) JSON'a çevir
                request.httpBody = try encoder.encode(task)
                
            } catch {
                print("TaskVM Güncelleme Hatası (JSON Encode): \(error)")
                return
            }
            
            // 5. İsteği gönder
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else { // Başarılı güncelleme '200 OK' döner
                    
                    print("TaskVM Güncelleme Hatası (Sunucu)")
                    // Hata olursa, UI'ın güncel kalması için listeyi yeniden çek
                    DispatchQueue.main.async { self.fetchTasks() }
                    return
                }
                
                // Başarılı olduysa, konsola yazdır
                print("TaskVM: Görev ID \(id) sunucudan başarıyla güncellendi.")
                
                // (fetchTasks() yapmaya gerek yok, çünkü UI zaten
                // EditTaskView'dan güncel veriyle dönüyor.
                // Ama garanti olması için listeyi yeniden çekmek en iyisidir.)
                DispatchQueue.main.async {
                    self.fetchTasks()
                }
                
            }.resume()
        }
}
