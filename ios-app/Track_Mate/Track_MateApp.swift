//
//  Track_MateApp.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

@main
struct TrackMateApp: App {
    
    // 1. ViewModel'i (motoru) en üst seviyede oluşturuyoruz.
    //    Uygulama yaşadığı sürece bu ViewModel de yaşayacak.
    @StateObject private var userVM = UserViewModel()

    var body: some Scene {
        WindowGroup {
            // 2. Karar mekanizması:
            //    Eğer kullanıcı giriş yapmışsa (init() sayesinde), HomeView'i göster.
            if userVM.isLoggedIn {
                HomeView()
                    .environmentObject(userVM) // VM'i HomeView'a ve alt sekmelerine aktar
            } else {
                //    Giriş yapmamışsa, LoginView'i göster.
                LoginView()
                    .environmentObject(userVM) // VM'i LoginView'a aktar
            }
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
