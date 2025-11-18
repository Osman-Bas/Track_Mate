//
//  AIViewModel.swift
//  Track_Mate
//
//  Created by Osman Baş on 18.11.2025.
//
import Foundation
internal import Combine

// --- 1. MODEL (Sözleşmeye Uygun) ---
struct AISuggestion: Identifiable, Codable {
    let id: String
    let title: String
    let recommendation: String
    let type: String // "productivity", "wellness" vb.
    
    // İkon belirlemek için yardımcı (computed) özellik
    var iconName: String {
        switch type {
        case "productivity": return "timer"
        case "activity": return "figure.run"
        case "wellness": return "heart.fill"
        case "media": return "play.tv.fill"
        default: return "star.fill"
        }
    }
}

struct AIResponse: Codable {
    let suggestions: [AISuggestion]
}

// --- 2. VIEW MODEL (Motor) ---
class AIViewModel: ObservableObject {
    
    @Published var suggestions: [AISuggestion] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Local IP Adresiniz (Değişirse burayı güncelleyin)
    private let apiBaseURL = "http://localhost:3000/api/ai/recommendations"
    
    // Cache (Önbellek) Anahtarları
    private let suggestionsKey = "cachedSuggestions"
    private let lastFetchDateKey = "lastFetchDate"
    
    // --- AYAR: SOĞUMA SÜRESİ (COOLDOWN) ---
    // 300 Saniye = 5 Dakika.
    // Son çekilen verinin üzerinden 5 dakika geçmediyse API çağrılmaz.
    private let cooldownSeconds: TimeInterval = 30
    
    // Uygulama açılınca hafızadaki eski veriyi yükle
    init() {
        loadCachedSuggestions()
    }
    
    // --- ÖNERİLERİ GETİR (AKILLI FONKSİYON) ---
    // forceRefresh: true yaparsan süreyi beklemeden zorla çeker (Pull-to-refresh için)
    func fetchRecommendations(forceRefresh: Bool = false) {
        
        // 1. ZAMAN KONTROLÜ:
        // Eğer zorla yenileme İSTENMEDİYSE (forceRefresh == false)
        // VE veri hala tazeyse (isDataRecent == true), dur.
        if !forceRefresh && isDataRecent() {
            print("AI: Veriler henüz taze (Son 5 dk içinde çekildi). API çağrılmadı.")
            return
        }
        
        guard let token = KeychainService.readToken() else {
            self.errorMessage = "Giriş yapılmamış."
            return
        }
        
        guard let url = URL(string: apiBaseURL) else { return }
        
        // Yükleme başlıyor
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // AI yavaş düşünebilir, süreyi 120 saniye (2 dk) yapalım
        request.timeoutInterval = 120
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Yükleme bitti
            defer {
                DispatchQueue.main.async { self.isLoading = false }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Ağ Hatası: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                do {
                    let response = try JSONDecoder().decode(AIResponse.self, from: data)
                    self.suggestions = response.suggestions
                    
                    // --- BAŞARILI OLUNCA KAYDET ---
                    // Hem veriyi hem de ŞU ANKİ SAATİ kaydediyoruz.
                    self.saveSuggestionsToCache(response.suggestions)
                    
                    print("AI: Yeni öneriler başarıyla alındı ve kaydedildi.")
                    
                } catch {
                    print("AI Decode Hatası: \(error)")
                    self.errorMessage = "Yapay zeka cevabı anlaşılamadı."
                }
            }
        }.resume()
    }
    
    // --- YARDIMCI FONKSİYON: ZAMAN KONTROLÜ ---
    private func isDataRecent() -> Bool {
        // Son kayıt tarihini oku
        guard let lastDate = UserDefaults.standard.object(forKey: lastFetchDateKey) as? Date else {
            return false // Hiç tarih yoksa taze değildir, çek.
        }
        
        // Şu an ile son tarih arasındaki farkı (saniye) bul
        let timeSinceLastFetch = Date().timeIntervalSince(lastDate)
        
        // Fark 300 saniyeden az mı?
        return timeSinceLastFetch < cooldownSeconds
    }
    
    // Veriyi ve Tarihi Kaydet
    private func saveSuggestionsToCache(_ suggestions: [AISuggestion]) {
        if let encoded = try? JSONEncoder().encode(suggestions) {
            UserDefaults.standard.set(encoded, forKey: suggestionsKey)
            UserDefaults.standard.set(Date(), forKey: lastFetchDateKey) // <-- Saat burada kaydediliyor
        }
    }
    
    // Eski Veriyi Yükle
    private func loadCachedSuggestions() {
        if let data = UserDefaults.standard.data(forKey: suggestionsKey),
           let decoded = try? JSONDecoder().decode([AISuggestion].self, from: data) {
            self.suggestions = decoded
        }
    }
}
