//
//  StatsModels.swift
//  Track_Mate
//
//  Created by Osman Baş on 13.11.2025.
//

import Foundation

// Bu, Sude'nin göndereceği ana JSON objesinin tamamıdır
struct StatsSummary: Codable {
    let taskSummary: TaskSummary
    let priorityBreakdown: PriorityBreakdown
    let moodHistory: MoodHistory
    let weeklyActivity: [WeeklyActivityDay]
    
    var priorityChartData: [ChartDataPoint] {
            [
                .init(name: "Yüksek", count: priorityBreakdown.high),
                .init(name: "Orta", count: priorityBreakdown.medium),
                .init(name: "Düşük", count: priorityBreakdown.low)
            ]
        }

        // 'moodHistory' objesini grafiğin anlayacağı diziye çevirir
        var moodChartData: [ChartDataPoint] {
            [
                .init(name: "Harika", count: moodHistory.harika),
                .init(name: "Mutlu", count: moodHistory.mutlu),
                .init(name: "Normal", count: moodHistory.normal),
                .init(name: "Üzgün", count: moodHistory.uzgun),
                .init(name: "Berbat", count: moodHistory.berbat)
            ]
        }
}

// MARK: - TaskSummary
struct TaskSummary: Codable {
    let totalTasks: Int
    let completedTasks: Int
    let completionPercentage: Int
    let pendingTasks: Int
}

// MARK: - PriorityBreakdown
struct PriorityBreakdown: Codable {
    let high: Int
    let medium: Int
    let low: Int
}

// MARK: - MoodHistory
struct MoodHistory: Codable {
    let harika: Int
    let mutlu: Int
    let normal: Int
    let uzgun: Int
    let berbat: Int
}

// MARK: - Grafik (Chart) için Yardımcı Model
// Bu, hem 'Mood' hem de 'Priority' grafikleri için kullanılacak
struct ChartDataPoint: Identifiable {
    let name: String
    let count: Int

    // Identifiable olabilmesi için 'id' gerekiyor
    var id: String { name }
}

// MARK: - WeeklyActivity
// (Grafik kütüphanelerinin kullanabilmesi için Identifiable yapıyoruz)
struct WeeklyActivityDay: Codable, Identifiable {
    let day: String
    let completed: Int
    
    // Identifiable olabilmesi için 'id' gerekiyor
    var id: String { day } // "Pzt", "Sal" vb. benzersiz olduğu için 'id' olarak kullanabiliriz
}
