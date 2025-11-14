//
//  JournalHistoryView.swift
//  Track_Mate
//
//  Created by Osman Baş on 13.11.2025.
//

import SwiftUI

struct JournalHistoryView: View {
    
    // 1. Ana ekrandaki 'JournalViewModel'i dinle
    @EnvironmentObject var journalVM: JournalViewModel
    
    var body: some View {
        
        // --- YENİ KOD BAŞLANGICI ---
        Group { // Birden fazla durumu yönetmek için Group kullan
            
            if journalVM.isHistoryLoading {
                // DURUM 1: YÜKLENİYOR
                ProgressView()
                
            } else if journalVM.pastEntries.isEmpty {
                // DURUM 2: YÜKLEME BİTTİ AMA LİSTE BOŞ
                Text("Henüz hiç günlük kaydınız yok.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
            } else {
                // DURUM 3: VERİ GELDİ
                List(journalVM.pastEntries) { entry in
                    // ... (Satır tasarımı - değişiklik yok) ...
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.mood.capitalized)
                                .font(.headline)
                                .padding(8)
                                .background(moodColor(for: entry.mood).opacity(0.15))
                                .cornerRadius(10)
                            Spacer()
                            Text(formatDate(entry.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !entry.journal.isEmpty {
                            Text(entry.journal)
                                .font(.body)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        // --- YENİ KOD SONU ---
        
        .navigationTitle("Geçmiş Günlükler")
        .onAppear {
            // Bu ekran (Geçmiş) AÇILDIĞINDA verileri çek
            print("JournalHistoryView göründü, geçmiş günlükler çekiliyor...")
            journalVM.fetchJournalEntries()
        }
    }
    
    // --- YARDIMCI FONKSİYONLAR ---
    
    // Ruh haline göre renk döndüren fonksiyon
    func moodColor(for mood: String) -> Color {
        switch mood {
        case "harika": return .green
        case "mutlu": return .yellow
        case "normal": return .blue
        case "uzgun": return .gray
        case "berbat": return .red
        default: return .purple
        }
    }
    
    // Backend'den gelen "createdAt" tarih string'ini formatlar
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            displayFormatter.locale = Locale(identifier: "tr_TR") // Türkçe tarih
            return displayFormatter.string(from: date)
        }
        return "Tarih yok"
    }
}

// MARK: - Preview
struct JournalHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        // Önizlemenin çalışması için sahte bir ViewModel oluştur
        let vm = JournalViewModel()
        vm.pastEntries = [
            JournalEntry(id: "1", mood: "harika", journal: "Bugün her şey harikaydı, API'leri bağladık.", createdAt: "2025-11-13T10:00:00Z"),
            JournalEntry(id: "2", mood: "normal", journal: "Sadece kod yazdım.", createdAt: "2025-11-12T15:30:00Z"),
            JournalEntry(id: "3", mood: "uzgun", journal: "", createdAt: "2025-11-11T12:00:00Z")
        ]
        
        return NavigationStack { // Önizleme de bir NavigationStack'te olmalı
            JournalHistoryView()
                .environmentObject(vm)
        }
    }
}

