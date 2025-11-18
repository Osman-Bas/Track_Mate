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
    let moodEmojis: [String: String] = [
        "Berbat": "😠",
        "Üzgün": "😟",
        "Normal": "😐",
        "Mutlu": "🙂",
        "Harika": "😄"
    ]
    
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
                VStack(spacing: 40) {
                    
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
                        VStack(spacing: 15) {
                            Text("Görev Tamamlama Özeti")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // ---- YENİ GÜVENLİ GÖSTERGE (ZSTACK/GAUGE) ----
                            
                            // ZStack, hem HALKAYI (altta) hem de METNİ (üstte) tutar
                            ZStack {
                                
                                // Katman 1: SADECE HALKA
                                Gauge(value: Double(summary.taskSummary.completionPercentage), in: 0...100) {
                                    
                                    // Halkanın ALTINDAKİ etiket (Bu doğru)
                                    Text("\(summary.taskSummary.completedTasks) tamamlandı")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                } currentValueLabel: {
                                    // Halkanın ORTASINDAKİ etiketi BOŞ BIRAK
                                    EmptyView()
                                }
                                .gaugeStyle(.accessoryCircularCapacity)
                                .tint(Color("yesil"))
                                .scaleEffect(2.5) // HALKAYI BÜYÜT
                                
                                
                                // Katman 2: YÜZDE METNİ (Ayrı Katman)
                                // Bu metin, scaleEffect(1.5)'ten ETKİLENMEZ
                                Text("%\(summary.taskSummary.completionPercentage)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded)) // <-- İSTEDİĞİNİZ BOYUT
                                    .foregroundColor(Color("yesil"))
                            }
                            .frame(height: 150)
                            // ---- GAUGE SONU ----
                            Text("Tamamlanan Görev: \(summary.taskSummary.completedTasks)/\(summary.taskSummary.totalTasks)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial) // Özel renginiz
                        .cornerRadius(20)
                        .padding(.horizontal) // Kenarlara boşluk
                        
                        
                        // --- AŞAMA 2: KAYDIRILABİLİR GRAFİKLER (CAROUSEL) ---
                        TabView(selection: $selectedChartPage) {
                            
                            // --- Sayfa 1: Haftalık Aktivite ---
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Bu Hafta Tamamlanan Görevler")
                                    .font(.title2.bold())
                                
                                Chart(summary.weeklyActivity) { dayData in
                                    // ---- YENİ: ÇİZGİ İŞARETİ ----
                                    LineMark(
                                        x: .value("Gün", dayData.day),
                                        y: .value("Tamamlanan", dayData.completed)
                                    )
                                    .interpolationMethod(.catmullRom) // Çizgiyi daha yumuşak yapar
                                    .foregroundStyle(Color("yesil")) // Çizgi rengi
                                    
                                    // ---- YENİ: NOKTA İŞARETİ (Her veri noktası için) ----
                                    PointMark(
                                        x: .value("Gün", dayData.day),
                                        y: .value("Tamamlanan", dayData.completed)
                                    )
                                    .foregroundStyle(Color("yesil")) // Nokta rengi
                                    .annotation(position: .top, alignment: .center) {
                                        if dayData.completed > 0 {
                                            Text("\(dayData.completed)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                // Grafiğin altındaki X eksenini özelleştir (Tam gün ismini gösterir)
                                .chartXAxis {
                                    AxisMarks(values:  .automatic) { value in
                                        AxisGridLine() // Dikey ızgara çizgisi
                                        AxisTick()     // Küçük çentik
                                        AxisValueLabel() // Formatlama YOK (veriyi olduğu gibi göster)
                                    }
                                }
                                // Grafiğin solundaki Y eksenini özelleştir (Sadece tam sayıları gösterir)
                                .chartYAxis {
                                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel()
                                    }
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
                                Text("30 Günlük Ruh Hali Dağılımı")
                                    .font(.title2.bold())
                                
                                Chart(summary.moodChartData) { dataPoint in
                                    // ---- YENİ: YATAY ÇUBUK İŞARETİ ----
                                    BarMark(
                                        x: .value("Sayı", dataPoint.count),    // X ekseninde sayı (yatay çubuk)
                                        y: .value("Ruh Hali", dataPoint.name) // Y ekseninde ruh hali ismi
                                    )
                                    .foregroundStyle(Color("yesil")) // Ruh haline göre renk
                                    .cornerRadius(5) // Çubuk köşelerini yumuşat
                                    .annotation(position: .trailing, alignment: .center) {
                                        // Her çubuğun sağına sayıyı yaz
                                        if dataPoint.count > 0 {
                                            Text("\(dataPoint.count)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .chartXAxis(.hidden) // Yatay eksendeki sayıları gizle (çubukların üzerinde var)
                                .chartYAxis {
                                    AxisMarks(preset: .automatic, values: .automatic) { value in
                                        // 'value' (değer), "mutlu", "normal" gibi bir String içerir
                                        // Onu 'as: String' ile almamız lazım
                                        if let moodName = value.as(String.self) {
                                            
                                            AxisValueLabel(horizontalSpacing: 8) {
                                                // --- YENİ ÖZEL ETİKET ---
                                                HStack(spacing: 4) {
                                                    // 1. Emoji'yi sözlükten al
                                                    Text(moodEmojis[moodName] ?? "❓")
                                                    
                                                    // 2. Metni al (artık capitalized yapmaya gerek yok,
                                                    //    StatsModels'da "Mutlu" diye geliyor)
                                                    Text(moodName)
                                                }
                                                .font(.caption) // Etiketlerin çok büyük olmaması için
                                                .padding(.trailing, 4) // Sağa biraz boşluk
                                                // --- YENİ ÖZEL ETİKET SONU ---
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                // .chartLegend(position: .bottom, alignment: .center) // Bu satır SİLİNDİ
                                
                            }
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .tag(1) // Bu, 1 numaralı sayfa
                            
                            
                            // --- Sayfa 3: Görev Öncelik Dağılımı (Fikir 2: Lollipop) ---
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Haftalık Görev Öncelik Dağılımı")
                                    .font(.title2.bold())
                                
                                Chart(summary.priorityChartData) { dataPoint in
                                    // 1. İnce "Sap" (Çizgi)
                                    RuleMark(
                                        x: .value("Öncelik", dataPoint.name),
                                        yStart: .value("Başlangıç", 0),
                                        yEnd: .value("Sayı", dataPoint.count)
                                    )
                                    .foregroundStyle(Color.gray.opacity(0.3)) // Soluk gri sap
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    
                                    // 2. "Şeker" (Nokta)
                                    PointMark(
                                        x: .value("Öncelik", dataPoint.name),
                                        y: .value("Sayı", dataPoint.count)
                                    )
                                    .symbolSize(250) // Nokta boyutu
                                    
                                    // ---- 1. DÜZELTME ----
                                    // Rengi "yesil" yap
                                    .foregroundStyle(Color("yesil"))
                                    // ---- 1. DÜZELTME SONU ----
                                    
                                    .annotation(position: .top) { // Sayıyı üste yaz
                                        if dataPoint.count > 0 {
                                            Text("\(dataPoint.count)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                // ---- 2. DÜZELTME ----
                                // Renk göstergesini (Lejantı) gizle
                                .chartLegend(.hidden)
                                .chartXScale(domain: ["Düşük", "Orta", "Yüksek"])
                                // ---- 2. DÜZELTME SONU ----
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
