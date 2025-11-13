//
//  JournalViewModel.swift
//  Track_Mate
//
//  Created by Osman Baş on 13.11.2025.
//

import Foundation
internal import Combine

// Sude'nin 'JournalEntry.js' modeline uyan
// yeni bir Swift 'struct'ı oluşturuyoruz.
struct JournalEntry: Identifiable, Codable, Hashable {
    var id: String?
    var mood: String
    var journal: String
    var createdAt: String // Tarihi String olarak alacağız (şimdilik)
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mood, journal, createdAt
    }
}

class JournalViewModel: ObservableObject {
    
    // API Adresleri
    // İki farklı 'base URL'e ihtiyacımız var
    private let authApiURL = "http://192.168.8.164:3000/api/auth"
    private let journalApiURL = "http://192.168.8.164:3000/api/journal"
    
    // MARK: - @Published Değişkenleri
    // Bu, "Geçmiş Günlükler" sekmesini dolduracak
    @Published var pastEntries: [JournalEntry] = []
    
    // Bu, "Yeni Giriş" sekmesindeki TextEditor'a bağlanacak
    @Published var journalText: String = ""
    
    // Bu, "Yeni Giriş" sekmesindeki 5'li ruh hali seçimine bağlanacak
    @Published var selectedMood: String = "normal" // Varsayılan değer
    
    // MARK: - 1. Anlık Ruh Halini Güncelle (AI İçin)
    // PATCH /api/auth/mood
    func updateCurrentMood(mood: String) {
        print("Anlık ruh hali güncelleniyor: \(mood)")
        guard let token = KeychainService.readToken() else { return }
        
        let urlString = "\(authApiURL)/mood"
        guard let url = URL(string: urlString) else { return }
        
        // Göndereceğimiz JSON: { "mood": "..." }
        let body: [String: String] = ["mood": mood]
        guard let jsonData = try? JSONEncoder().encode(body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                print("Anlık Mood Güncelleme Hatası!")
                return
            }
            
            // Cevabı (Response) kontrol et: { "success": true, "newMood": "mutlu" }
            if let responseJSON = try? JSONDecoder().decode([String: String].self, from: data) {
                print("Anlık Ruh Hali başarıyla güncellendi: \(responseJSON["newMood"] ?? "??")")
            }
        }.resume()
    }
    
    // MARK: - 2. Günlük Arşivini Kaydet (İstatistikler İçin)
    // POST /api/journal
    func saveDailyEntry() {
        print("Günlük arşivi kaydediliyor...")
        guard let token = KeychainService.readToken() else { return }
        
        let urlString = journalApiURL
        guard let url = URL(string: urlString) else { return }
        
        // Göndereceğimiz JSON: { "mood": "...", "journal": "..." }
        let body: [String: String] = [
            "mood": self.selectedMood,
            "journal": self.journalText
        ]
        guard let jsonData = try? JSONEncoder().encode(body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else { // 201 = Created
                print("Günlük Kaydetme Hatası!")
                return
            }
            
            print("Günlük başarıyla 'arşive' kaydedildi.")
            
            // Kaydetme başarılı olduktan sonra,
            // "Geçmiş Günlükler" listesini yenileyelim
            DispatchQueue.main.async {
                self.fetchJournalEntries()
                
                // Formu temizle
                self.journalText = ""
                self.selectedMood = "normal"
            }
        }.resume()
    }
    
    // MARK: - 3. Geçmiş Günlükleri Getir (Geçmiş Sekmesi İçin)
    // GET /api/journal
    func fetchJournalEntries() {
        print("Geçmiş günlükler çekiliyor...")
        guard let token = KeychainService.readToken() else { return }
        
        let urlString = journalApiURL
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Geçmiş Günlükler: Veri gelmedi")
                return
            }
            
            do {
                // Sude'nin [{_id: "...", ...}] dizisini çöz
                let entries = try JSONDecoder().decode([JournalEntry].self, from: data)
                
                DispatchQueue.main.async {
                    self.pastEntries = entries
                    print("Geçmiş \(entries.count) günlük kaydı başarıyla çekildi.")
                }
            } catch {
                print("Geçmiş Günlükler Decode Hatası: \(error)")
            }
        }.resume()
    }
}
