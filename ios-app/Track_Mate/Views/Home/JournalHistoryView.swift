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
    @State private var selectedEntry: JournalEntry? = nil
    var body: some View {
        ZStack {
            
            // KATMAN 1: ARKA PLAN RENGİ
            Color("bej")
                .ignoresSafeArea()
            // Ana Konteyner (VStack)
            VStack {
                
                // --- DURUM KONTROLÜ ---
                if journalVM.isHistoryLoading {
                    // DURUM 1: YÜKLENİYOR
                    Spacer()
                    ProgressView("Geçmiş Günlükler Yükleniyor...")
                    Spacer()
                    
                } else {
                    
                    // --- DURUM 2: YÜKLEME BİTTİ ---
                    
                    // 1. TAKVİMİN KENDİSİ (Karta dönüştürüldü)
                    CalendarView(
                        pastEntries: $journalVM.pastEntries,
                        selectedEntry: $selectedEntry
                    )
                    .padding() // Takvime iç boşluk ver
                    .background(.thinMaterial) // "Buzlu cam" arka planı
                    .cornerRadius(20) // Köşeleri yuvarlat
                    .padding(.horizontal) // Kartın kenarlara yapışmasını engelle
                    .frame(height: 390) // Yüksekliği koru
                    
                    
                    // 2. SEÇİLEN GÜNÜN DETAYI (Karta dönüştürüldü)
                    
                    // --- YENİ KAPSAYICI KART ---
                    VStack {
                        if let entry = selectedEntry {
                            // DURUM 1: GÜNLÜK SEÇİLDİ
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text(entry.mood.capitalized)
                                        .font(.title2.bold())
                                        .padding(10)
                                        .background(moodColor(for: entry.mood).opacity(0.15))
                                        .cornerRadius(10)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(entry.createdAt))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Günlük metni için kaydırılabilir alan
                                ScrollView {
                                    Text(entry.journal.isEmpty ? "Bu gün için günlük metni girilmemiş." : entry.journal)
                                        .font(.body)
                                        .foregroundColor(entry.journal.isEmpty ? .secondary : .primary)
                                        .frame(maxWidth: .infinity, alignment: .leading) // Metni sola yasla
                                }
                            }
                            .transition(.opacity) // Sadece yumuşak geçiş
                            
                        } else {
                            // DURUM 2: GÜNLÜK SEÇİLMEDİ (Placeholder)
                            Spacer()
                            Text("Detayları görmek için takvimden renkli bir güne dokunun.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        }
                    }
                    .frame(height: 180) // Karta sabit bir yükseklik ver (Takvimle denge)
                    .padding() // Kartın iç boşluğu
                    .background(.thinMaterial) // "Buzlu cam" arka plan
                    .cornerRadius(20) // Köşeleri yuvarlat
                    .padding(.horizontal) // Kartın dış boşluğu
                    .padding(.bottom, 5,)
                    .padding(.top, 20)// Kartın alta yapışmaması için
                    // --- YENİ KAPSAYICI KART SONU ---
                }
            }
            .animation(.default, value: journalVM.isHistoryLoading) // Yükleme bittiğinde yumuşak geçiş
            .animation(.default, value: selectedEntry) // Detay ekranı geldiğinde yumuşak geçiş
            
            .toolbar { // <-- YENİ BLOK BAŞLANGICI
                // Başlığın olduğu orta alana (.principal) özel bir View yerleştir
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.headline)
                            .foregroundColor(.black) // İkona renk verelim
                        
                        Text("Geçmiş Günlükler")
                            .font(.headline) // Metni de ikonla aynı boyuta getir
                            .fontWeight(.bold)
                    }
                }
            } // <-- YENİ BLOK SONU
            
            .onAppear {
                // Bu ekran (Geçmiş) AÇILDIĞINDA verileri çek
                print("JournalHistoryView göründü, geçmiş günlükler çekiliyor...")
                journalVM.fetchJournalEntries()
            }
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

