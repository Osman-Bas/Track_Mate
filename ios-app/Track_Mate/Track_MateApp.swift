//
//  Track_MateApp.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

@main
struct TrackMateApp: App {
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
//@main
//struct TrackMateApp: App {
//    
//    // --- GEÇİCİ KOD BAŞLANGICI ---
//    // 1. Sunucu kapalıyken test için sahte bir UserViewModel oluştur
//    private var testUserVM: UserViewModel {
//        let vm = UserViewModel()
//        // 2. Sahte bir kullanıcı yarat (DashboardView'un çökmemesi için)
//        vm.currentUser = User(
//            id: "fakeUserID123",
//            fullName: "Osman Baş (Test)", // fullName zorunlu
//            username: "osman_test",
//            email: "test@mail.com",
//            profilePictureUrl: "" // Profil resmi yok
//        )
//        // 3. Giriş yapmış gibi davran
//        vm.isLoggedIn = true
//        return vm
//    }
//    // --- GEÇİCİ KOD SONU ---
//    
//    var body: some Scene {
//        WindowGroup {
//            // ESKİ: LoginView()
//            
//            // YENİ: Doğrudan HomeView'i yükle ve sahte ViewModel'i enjekte et
//            HomeView()
//                .environmentObject(testUserVM)
//        }
//    }
//}
