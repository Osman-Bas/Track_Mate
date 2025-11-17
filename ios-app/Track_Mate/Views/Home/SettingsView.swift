//
//  SettingsView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userVM: UserViewModel
    var body: some View {
            NavigationStack {
                // iOS'taki standart "Ayarlar" menüleri için
                // 'List' veya 'Form' kullanmak en temiz yoldur.
                Form {
                    // MARK: - Bölüm 1: Hesap
                    Section(header: Text("Hesap")) {
                        
                        // (Eğer kullanıcı adını göstermek istersek)
                        if let user = userVM.currentUser {
                            HStack {
                                Text("Kullanıcı Adı")
                                Spacer()
                                Text(user.username)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("E-posta")
                                Spacer()
                                Text(user.email)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // --- ÇIKIŞ YAP BUTONU ---
                        Button(role: .destructive, action: {
                            // ViewModel'deki logout fonksiyonunu çağır
                            userVM.logout()
                        }) {
                            Text("Çıkış Yap")
                        }
                    }
                    
                    // MARK: - Bölüm 2: Uygulama
                    Section(header: Text("Uygulama")) {
                        Text("Sürüm 2.1.3")
                            .foregroundColor(.secondary)
                        // (Gelecekte buraya "Bildirim Ayarları" vb. eklenebilir)
                    }
                    
                } // Form sonu
                .navigationTitle("Ayarlar")
            }
        }
}
