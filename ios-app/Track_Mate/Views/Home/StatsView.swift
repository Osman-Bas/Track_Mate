//
//  StatsView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI
import Charts

struct StatsView: View {
    
    // 1. Yeni ViewModel'imizi (motor) oluşturuyoruz
    @StateObject private var statsVM = StatsViewModel()
    @State private var selectedChartPage: Int = 0
    
    var body: some View {
            NavigationStack {
                
                // --- DÜZELTME 1: Ana ZStack ---
                // 'bej' rengini, her şeyin arkasında duran
                // bir 'ZStack'in en alt katmanına taşıyoruz.
                ZStack {
                    
                    // KATMAN 1: ARKA PLAN RENGİ
                    Color("bej")
                        .ignoresSafeArea()

                    // KATMAN 2: ANA İÇERİK
                    VStack(spacing: 20) {
                        
                        // Color("bej") buradan SİLİNDİ (artık arkada)
                        
                        // 1. Durum Kontrolü (isLoading, error, summary)
                        if statsVM.isLoading {
                            Spacer()
                            ProgressView()
                            Spacer()
                            
                        } else if let errorMessage = statsVM.errorMessage {
                            Spacer()
                            Text("Hata: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                            Spacer()
                            
                        } else if let summary = statsVM.summary {
                            
                            // --- AŞAMA 1: SABİT ÜST KART (YÜZDE) ---
                            VStack {
                                Text("Görev Tamamlama Özeti")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("%\(summary.taskSummary.completionPercentage)")
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("\(summary.taskSummary.completedTasks) / \(summary.taskSummary.totalTasks) Görev Tamamlandı")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color("pembe")) // Özel renginiz
                            .cornerRadius(20)
                            .padding(.horizontal) // Kenarlara boşluk
                            

                            // --- AŞAMA 2: KAYDIRILABİLİR GRAFİKLER (CAROUSEL) ---
                            TabView(selection: $selectedChartPage) {
                                
                                // --- Sayfa 1: Haftalık Aktivite ---
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Haftalık Aktivite")
                                        .font(.title2.bold())
                                    
                                    Chart(summary.weeklyActivity) { dayData in
                                        BarMark(
                                            x: .value("Gün", dayData.day),
                                            y: .value("Tamamlanan", dayData.completed)
                                        )
                                        .foregroundStyle(by: .value("Gün", dayData.day))
                                    }
                                    .frame(height: 200)
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(20)
                                .padding(.horizontal)
                                .tag(0) // Bu, 0 numaralı sayfa

                                
                                // --- Sayfa 2: Ruh Hali Dağılımı ---
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Ruh Hali Dağılımı")
                                        .font(.title2.bold())
                                    
                                    Chart(summary.moodChartData) { dataPoint in
                                        SectorMark(
                                            angle: .value("Sayı", dataPoint.count),
                                            innerRadius: .ratio(0.5),
                                            angularInset: 1.5
                                        )
                                        .foregroundStyle(by: .value("Ruh Hali", dataPoint.name))
                                        .cornerRadius(5)
                                    }
                                    .frame(height: 200)
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(20)
                                .padding(.horizontal)
                                .tag(1) // Bu, 1 numaralı sayfa

                                
                                // --- Sayfa 3: Öncelik Dağılımı ---
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Görev Öncelik Dağılımı")
                                        .font(.title2.bold())
                                    
                                    Chart(summary.priorityChartData) { dataPoint in
                                        SectorMark(
                                            angle: .value("Sayı", dataPoint.count),
                                            innerRadius: .ratio(0.5),
                                            angularInset: 1.5
                                        )
                                        .foregroundStyle(by: .value("Öncelik", dataPoint.name))
                                        .cornerRadius(5)
                                    }
                                    .frame(height: 200)
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(20)
                                .padding(.horizontal)
                                .tag(2) // Bu, 2 numaralı sayfa
                                
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: 250)
                            
                            
                            // --- Özel Daireler (Page Indicator) ---
                            // (Kodunuz mükemmeldi, aynen aldım)
                            HStack(spacing: 10) {
                                ForEach(0..<3) { index in
                                    if selectedChartPage == index {
                                        Circle()
                                            .fill(Color("yesil")) // Özel renginiz
                                            .frame(width: 10, height: 10)
                                    } else {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                            .animation(.spring(), value: selectedChartPage)

                            Spacer() // Her şeyi yukarı iter
                            
                        } else {
                            // --- DURUM 4: BAŞLANGIÇ (Boş) ---
                            Text("İstatistikler yükleniyor...")
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                        }
                    } // Ana VStack sonu
                    
                } // Ana ZStack sonu
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text("İstatistikler")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        // .padding(.top, 50) 'hack'i buradan SİLİNDİ
                    }
                }
                .navigationBarTitleDisplayMode(.inline) // Bu, başlığın yerini standartlaştırır
                .onAppear {
                    print("StatsView göründü, istatistikler çekiliyor...")
                    statsVM.fetchStats()
                }
            }
        }
    
    
    
    
}

// MARK: - Preview
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
