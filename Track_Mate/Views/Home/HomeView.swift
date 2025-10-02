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
            
            AIView()
                .tabItem {
                    Label("AI Öneri", systemImage: "brain.head.profile")
                }
            
            StatsView()
                .tabItem {
                    Label("İstatistikler", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}
