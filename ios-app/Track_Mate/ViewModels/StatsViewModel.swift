//
//  StatsViewModel.swift
//  Track_Mate
//
//  Created by Osman Baş on 13.11.2025.
//

import Foundation
internal import Combine // ObservableObject için

class StatsViewModel: ObservableObject {
    
    // API'den gelen tüm istatistik verisini bu değişkende tutacağız
    @Published var summary: StatsSummary? = nil
    
    // Tıpkı TaskViewModel'deki gibi yükleme ve hata durumları
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // API Adresi (Sude'nin server.js'ine göre)
    private let apiBaseURL = "http://192.168.8.164:3000/api/stats"

    // MARK: - İstatistikleri Getir (GET /api/stats/summary)
    
    func fetchStats() {
        guard let token = KeychainService.readToken() else {
            print("StatsVM: Token yok, istatistikler getirilemedi.")
            self.errorMessage = "Giriş yapılmamış."
            return
        }
        
        let urlString = "\(apiBaseURL)/summary"
        guard let url = URL(string: urlString) else {
            print("StatsVM: Geçersiz URL")
            self.errorMessage = "Geçersiz API Adresi"
            return
        }
        
        // --- Yüklemeyi Başlat ---
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil // Eski hatayı temizle
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // --- Yüklemeyi Bitir ---
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            
            // 1. Ağ Hatası Kontrolü
            if let error = error {
                print("StatsVM Ağ Hatası: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Ağ Hatası: Sunucuya bağlanılamadı."
                }
                return
            }
            
            // 2. HTTP Cevap Kodu Kontrolü
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("StatsVM Sunucu Hatası: Kod \( (response as? HTTPURLResponse)?.statusCode ?? 0)")
                DispatchQueue.main.async {
                    self.errorMessage = "Sunucudan geçerli bir cevap alınamadı."
                }
                return
            }
            
            // 3. Veri Kontrolü
            guard let data = data else {
                print("StatsVM: Veri gelmedi (data is nil)")
                DispatchQueue.main.async {
                    self.errorMessage = "Sunucudan boş veri geldi."
                }
                return
            }
            
            // 4. JSON Çözümleme (Decode)
            DispatchQueue.main.async {
                do {
                    // Gelen JSON'u 'StatsModels.swift' dosyamızdaki
                    // ana 'StatsSummary' struct'ına çevir
                    let summaryData = try JSONDecoder().decode(StatsSummary.self, from: data)
                    
                    // Başarılı! Veriyi 'summary' değişkenine ata
                    self.summary = summaryData
                    print("StatsVM: İstatistikler başarıyla çekildi.")
                    
                } catch {
                    print("StatsVM JSON Decode Hatası: \(error)")
                    self.errorMessage = "Sunucudan gelen veri anlaşılamadı."
                }
            }
        }.resume()
    }
}
