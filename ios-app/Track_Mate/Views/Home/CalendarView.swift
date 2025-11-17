//
//  CalendarView.swift
//  Track_Mate
//
//  Created by Osman Baş on 17.11.2025.
//

import SwiftUI
import FSCalendar // 1. Yeni kütüphanemizi import ediyoruz
import UIKit

// Bu struct, FSCalendar'ı SwiftUI içinde kullanılabilir hale getirir.
struct CalendarView: UIViewRepresentable {
    
    // ViewModel'den gelen "Geçmiş Günlükler" listesi
    @Binding var pastEntries: [JournalEntry]
    
    // Kullanıcı bir güne tıkladığında, o güne ait
    // günlüğü bulup buraya atayacağız
    @Binding var selectedEntry: JournalEntry?
    
    // MARK: - 1. View'ı Oluştur (makeUIView)
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        
        // 1. Coordinator'ı (Köprüyü) ayarla
        // FSCalendar, verileri ('DataSource') ve tıklamaları ('Delegate')
        // Coordinator üzerinden yönetecek.
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        
        // 2. Takvimi Ayarla
        calendar.locale = Locale(identifier: "tr_TR") // Türkçe
        calendar.scrollDirection = .vertical // Dikey kaydırma
        calendar.backgroundColor = .clear
        
        // --- YENİ GÖRSEL AYARLAR ---
                
                // 1. Başlık (Header) - "Kasım 2025"
                calendar.appearance.headerTitleFont = .systemFont(ofSize: 22, weight: .bold)
                calendar.appearance.headerTitleColor = .label
                
                // 2. Hafta Günleri (Pzt, Sal, Çar...)
                calendar.appearance.weekdayFont = .systemFont(ofSize: 12, weight: .medium)
                calendar.appearance.weekdayTextColor = .secondaryLabel // (Soluk gri)
                
                // 3. Rakamların (Günler) Genel Rengi
                calendar.appearance.titleDefaultColor = .label // (Normal rakam rengi)

                // 4. "Bugün" (Today) Rengi
                // (Arka planı olmasın, 'fillDefaultColor' ile çakışmasın)
                calendar.appearance.todayColor = .clear
                // "Bugün" rakamı, seçili değilse, normal bir günden farksız olsun
                calendar.appearance.titleTodayColor = nil // (nil = 'titleDefaultColor'ı kullan)
                
                // 5. Seçili Gün (Tıklanan Gün) Rengi
                // (Arka planı renkli günlerle karışmaması için çok soluk bir mavi)
                calendar.appearance.selectionColor = .systemBlue.withAlphaComponent(0.2)
                // Seçili günün rakamı normal kalsın
                calendar.appearance.titleSelectionColor = nil // (nil = 'titleDefaultColor'ı kullan)
                
                // 6. Çıkıntı Yapan Günler (Placeholder)
                // (Önceki/Sonraki ayın günlerini soluk göster)
                calendar.appearance.caseOptions = .weekdayUsesSingleUpperCase
        calendar.placeholderType = .none // Diğer ayların günlerini gösterme
                calendar.appearance.titlePlaceholderColor = .systemGray4 // Onları çok soluk yap
                
                // --- YENİ BLOK SONU ---

                return calendar
            }

    // MARK: - 2. View'ı Güncelle (updateUIView)
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        // Coordinator'a en güncel verileri ver
        context.coordinator.pastEntries = pastEntries
        context.coordinator.selectedEntry = selectedEntry
        
        // Takvime, o 'renkli daireleri' yeniden çizmesini söyle
        uiView.reloadData()
    }

    // MARK: - 3. Coordinator (Köprü)
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        
        var parent: CalendarView
        var pastEntries: [JournalEntry] = []
        var selectedEntry: JournalEntry? = nil
        
        // Formatter'ı bir kez oluşturmak performansı artırır
        private let isoFormatter = ISO8601DateFormatter()
        
        init(parent: CalendarView) {
            self.parent = parent
            self.isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            super.init()
        }
        
        // --- TIKLAMAYI YAKALAMA ---
        // Kullanıcı takvimde bir güne tıkladığında bu fonksiyon çalışır
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            // Tıklanan tarihe ait bir günlük (entry) var mı diye 'pastEntries' dizisinde ara
            let foundEntry = pastEntries.first { entry in
                guard let entryDate = isoFormatter.date(from: entry.createdAt) else { return false }
                // Tıklanan gün ile kayıttaki gün aynı mı?
                return Calendar.current.isDate(entryDate, inSameDayAs: date)
            }
            
            // Bulduğumuz günlüğü ana View'daki 'selectedEntry' değişkenine ata
            parent.selectedEntry = foundEntry
        }
        
        // --- İSTEĞİNİZİ YAPAN FONKSİYON 1: ARKA PLAN RENGİ ---
        // FSCalendar, her bir gün için bu fonksiyonu çalıştırır ve
        // "Bu günün arka planı ne renk olmalı?" diye sorar.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            
            // O güne ait bir günlük (entry) var mı diye ara
            let foundEntry = pastEntries.first { entry in
                guard let entryDate = isoFormatter.date(from: entry.createdAt) else { return false }
                return Calendar.current.isDate(entryDate, inSameDayAs: date)
            }
            
            if let entry = foundEntry {
                // EĞER O GÜN GÜNLÜK VARSA:
                // Ruh haline göre ARKA PLAN RENGİNİ döndür
                switch entry.mood {
                case "harika": return .systemGreen
                case "mutlu": return .systemYellow
                case "normal": return .systemBlue
                case "uzgun": return .systemGray
                case "berbat": return .systemRed
                default: return .systemPurple
                }
            }
            
            // O gün günlük yoksa, arka planı şeffaf yap (renk yok)
            return .clear
        }
        
        // --- İSTEĞİNİZİ YAPAN FONKSİYON 2: RAKAM RENGİ ---
        // FSCalendar, "Bu günün rakamı ne renk olmalı?" diye sorar.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
            
            // O güne ait bir günlük (entry) var mı diye ara
            let foundEntry = pastEntries.first { entry in
                guard let entryDate = isoFormatter.date(from: entry.createdAt) else { return false }
                return Calendar.current.isDate(entryDate, inSameDayAs: date)
            }
            
            if foundEntry != nil {
                // EĞER O GÜNÜN ARKA PLANI RENKLİYSE:
                // Rakam, arka planla kontrast oluştursun diye 'beyaz' olsun
                return .white
            }
            
            // O gün günlük yoksa, rakam varsayılan renginde kalsın
            return nil // (nil = varsayılan renk)
        }
    }
}
