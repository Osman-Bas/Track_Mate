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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 2. ViewModel'in durumunu kontrol ediyoruz
                    if statsVM.isLoading {
                        // --- DURUM 1: YÜKLENİYOR ---
                        ProgressView() // Dönen çember
                            .padding(.top, 50)
                        
                    } else if let errorMessage = statsVM.errorMessage {
                        // --- DURUM 2: HATA VAR ---
                        Text("Hata: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                        
                    } else if let summary = statsVM.summary {
                        // --- DURUM 3: BAŞARILI (Veri Geldi) ---
                        
                        // MARK: - 1. Görev Tamamlama (Donut Chart)
                        VStack {
                            Text("Görev Tamamlama Özeti")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // (completionPercentage kullanarak bir 'Gauge' veya 'Donut' grafiği)
                            // Şimdilik basit bir yüzde gösterimi:
                            Text("%\(summary.taskSummary.completionPercentage)")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("\(summary.taskSummary.completedTasks) / \(summary.taskSummary.totalTasks) Görev Tamamlandı")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(20)
                        
                        
                        // MARK: - 2. Haftalık Aktivite (Bar Chart)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Haftalık Aktivite (Tamamlanan Görevler)")
                                .font(.title2.bold())
                            
                            // Çubuk Grafik (Bar Chart)
                            Chart(summary.weeklyActivity) { dayData in
                                BarMark(
                                    x: .value("Gün", dayData.day),
                                    y: .value("Tamamlanan", dayData.completed)
                                )
                                .foregroundStyle(by: .value("Gün", dayData.day)) // Her çubuğu farklı renk yapar
                            }
                            .frame(height: 200) // Grafiğin yüksekliği
                        }
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(20)
                        
                        
                        // MARK: - 3. Ruh Hali Dağılımı (Pie Chart)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ruh Hali Dağılımı")
                                .font(.title2.bold())
                            
                            // Pasta Grafik (Pie Chart)
                            // 'moodChartData' dizisini kullanıyoruz
                            Chart(summary.moodChartData) { dataPoint in
                                SectorMark(
                                    angle: .value("Sayı", dataPoint.count),
                                    innerRadius: .ratio(0.5), // Ortası delik (Donut)
                                    angularInset: 1.5 // Dilimler arası boşluk
                                )
                                .foregroundStyle(by: .value("Ruh Hali", dataPoint.name))
                                .cornerRadius(5)
                            }
                            .frame(height: 200) // Grafiğin yüksekliği
                        }
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(20)
                        
                        
                        // MARK: - 4. Öncelik Dağılımı (Pie Chart)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Görev Öncelik Dağılımı")
                                .font(.title2.bold())
                            
                            // Pasta Grafik (Pie Chart)
                            // 'priorityChartData' dizisini kullanıyoruz
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
                        
                        
                    } else {
                        // --- DURUM 4: BAŞLANGIÇ (Boş) ---
                        // (Ekran ilk açıldığında, henüz yüklenmemişken)
                        Text("İstatistikler yükleniyor...")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    }
                    
                    Spacer() // Her şeyi yukarı iter
                }
                .padding()
                
            } // ScrollView sonu
            .navigationTitle("İstatistikler")
            .onAppear {
                // 3. Ekran açıldığı anda "motoru" çalıştır
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
