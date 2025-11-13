//
//  JournalEntryView.swift
//  Track_Mate
//
//  Created by Osman Baş on 13.11.2025.
//

import SwiftUI

struct JournalEntryView: View {
    
    
    @StateObject private var journalVM = JournalViewModel()
    
    let moodEmojis: [String: String] = [
        "berbat": "😠",
        "üzgün": "😟",
        "normal": "😐",
        "mutlu": "🙂",
        "harika": "😄"
    ]
    let moodOrder = ["berbat", "üzgün", "normal", "mutlu", "harika"]
    
    var body: some View {
        NavigationStack {
            // ZStack hizalamasını (alignment) kaldırıyoruz.
            ZStack {
                
                // --- KATMAN 1: ANA İÇERİK (Mood, Journal, Kaydet Butonu) ---
                // 'Kaydet' butonu artık bu VStack'in bir parçası
                VStack(spacing: 20) {
                    
                    // --- BÖLÜM 1: ANLIK RUH HALİ (AI İÇİN) ---
                    VStack(spacing: 15) {
                        Text("Bugün Nasılsın?")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        HStack(alignment: .center, spacing: 10) {
                            ForEach(moodOrder, id: \.self) { mood in
                                // ... (Emoji kodları - değişiklik yok) ...
                                let emoji = moodEmojis[mood] ?? "❓"
                                VStack(spacing: 4) {
                                    Text(emoji)
                                        .font(.system(size: 36))
                                    Text(mood.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(journalVM.selectedMood == mood ? Color.yellow.opacity(0.15) : Color.clear)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(journalVM.selectedMood == mood ? Color.yellow : Color.clear, lineWidth: 2)
                                )
                                .scaleEffect(journalVM.selectedMood == mood ? 1.05 : 1.0)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        journalVM.selectedMood = mood
                                        journalVM.updateCurrentMood(mood: mood)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    
                    
                    // --- BÖLÜM 2: GÜNÜN GÜNLÜĞÜ (STATS İÇİN) ---
                    VStack(spacing: 15) {
                        Text("Günün Nasıl Geçti?")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $journalVM.journalText)
                                .frame(height: 200)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                                .opacity(journalVM.journalText.isEmpty ? 0.8 : 1.0)
                            
                            if journalVM.journalText.isEmpty {
                                Text("Bugün neler oldu? Günün özetini buraya yaz...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    
                    // --- BÖLÜM 3: KAYDET BUTONU (YENİ YER) ---
                    // (Artık Spacer'dan ÖNCE. Onu yukarı iter)
                    Button(action: {
                        journalVM.saveDailyEntry()
                        // TODO: Başarılı olduğuna dair bir 'banner' göster
                    }) {
                        Text("Bugünü Günlüğüne Kaydet")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Spacer, tüm bu 3 bölümü yukarı iter
                    Spacer()
                    
                } // Ana VStack sonu
                .padding([.horizontal, .bottom])
                .padding(.top, -30)
                
                
                // --- KATMAN 2: FLOAT BUTON (GEÇMİŞE GİT) ---
                // (DashboardView'daki ile aynı kod)
                VStack {
                    Spacer() // Butonu alta iter
                    HStack {
                        Spacer() // Butonu sağa iter
                        
                        NavigationLink(destination: {
                            // TODO: Buraya 'JournalHistoryView' gelecek
                            JournalHistoryView()
                                                    .environmentObject(journalVM)
                        }) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        // Bu padding, butonun sağ alt köşede
                        // TabView'a çakışmadan durmasını sağlar
                        .padding()
                    }
                }
                
            } // ZStack sonu
            .toolbar { // <-- YENİ BLOK BAŞLANGICI
                // Başlığın olduğu orta alana (.principal) özel bir View yerleştir
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .font(.headline)
                            .foregroundColor(.blue) // İkona renk verelim
                        
                        Text("Günlük & Ruh Hali")
                            .font(.headline) // Metni de ikonla aynı boyuta getir
                            .fontWeight(.bold)
                    }.padding(.top, 50)
                }
            } // <-- YENİ BLOK SONU
            .onAppear {}
        }
    }
}
#Preview {
    JournalEntryView()
}
