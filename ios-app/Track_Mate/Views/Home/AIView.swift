//
//  AIView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

struct AIView: View {
    
    // 1. Motoru (ViewModel) bağlıyoruz
    @StateObject private var aiVM = AIViewModel()
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                // Arka Plan (Diğer sayfalarla uyumlu 'bej')
                Color("bej")
                    .ignoresSafeArea()
                
                VStack {
                    
                    // --- DURUM KONTROLÜ ---
                    if aiVM.isLoading {
                        Spacer()
                        ProgressView("Yapay Zeka Düşünüyor...")
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(10)
                        Spacer()
                        
                    } else if let errorMessage = aiVM.errorMessage {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Bir sorun oluştu")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Tekrar Dene") {
                                aiVM.fetchRecommendations()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        Spacer()
                        
                    } else if aiVM.suggestions.isEmpty {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Henüz Öneri Yok")
                                .font(.title2.bold())
                                .foregroundColor(.secondary)
                            Text("AI'ın seni tanıması için biraz görev tamamla veya günlük yaz.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Analizi Başlat") {
                                aiVM.fetchRecommendations()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color("yesil"))
                        }
                        Spacer()
                        
                    } else {
                        // --- VERİ GELDİ: ÖNERİ KARTLARI ---
                        ScrollView {
                            VStack(spacing: 20) {
                                
                                // Kullanıcıya hitap eden bir başlık
                                Text("Sana Özel Tavsiyelerim")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                ForEach(aiVM.suggestions) { suggestion in
                                    SuggestionCard(suggestion: suggestion)
                                }
                            }
                            .padding(.bottom)
                        }
                        // Çek-Yenile özelliği
                        .refreshable {
                                                    // Kullanıcı elle çektiği için "Zorla Yenile" diyoruz
                                                    aiVM.fetchRecommendations(forceRefresh: true)
                                                }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile") // Veya 'sparkles'
                            .font(.headline)
                            .foregroundColor(.purple) // AI için mor renk
                        
                        Text("AI Asistan")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Ekran açılınca önerileri çek
                // (Eğer liste boşsa çek, doluysa tekrar çekme - tercih meselesi)
                aiVM.fetchRecommendations()
            }
        }
    }
}

// --- ÖZEL BİLEŞEN: ÖNERİ KARTI ---
struct SuggestionCard: View {
    let suggestion: AISuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Başlık ve İkon
            HStack {
                Image(systemName: suggestion.iconName) // Modelden gelen ikon
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(typeColor.opacity(0.8))
                    .clipShape(Circle())
                
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Divider()
            
            // Öneri Metni
            Text(suggestion.recommendation)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true) // Metnin tamamını göster
            
            // Alt Bilgi (Tip)
            HStack {
                Spacer()
                Text(suggestion.type.uppercased())
                    .font(.caption2.bold())
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(.thinMaterial) // Buzlu cam efekti
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Öneri tipine göre renk belirle
    var typeColor: Color {
        switch suggestion.type {
        case "productivity": return .blue
        case "wellness": return .green
        case "activity": return .orange
        case "media": return .pink
        default: return .gray
        }
    }
}

// MARK: - Preview
struct AIView_Previews: PreviewProvider {
    static var previews: some View {
        AIView()
    }
}
