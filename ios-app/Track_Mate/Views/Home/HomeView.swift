//
//  HomeView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userVM: UserViewModel
    @StateObject var taskVM = TaskViewModel()
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(userVM)
                .environmentObject(taskVM)
                .tabItem {
                    Label("Ana Menü", systemImage: "house.fill")
                }
            
            JournalEntryView() // <-- DEĞİŞTİ
                .tabItem {
                    Label("Günlük", systemImage: "book.closed.fill") // <-- DEĞİŞTİ
                }
            
            StatsView()
                .tabItem {
                    Label("İstatistikler", systemImage: "chart.bar.fill")
                }
            
            AIView()
                .tabItem {
                    Label("AI Öneri", systemImage: "brain.head.profile")
                }
            
            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}
