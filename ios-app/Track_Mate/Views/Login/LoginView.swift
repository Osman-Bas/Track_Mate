//
//  LoginView.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var userVM = UserViewModel()
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isRegisterMode = false
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                // MARK: - Arka Plan Rengi
                Color(.systemGroupedBackground) // <-- YENİ (Dashboard ile aynı)
                    .ignoresSafeArea()
                VStack(spacing: 15) {
                    // MARK: - Logo/İkon
                    Image(systemName: "list.clipboard.fill") // <-- YENİ İKON
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle( // <-- YENİ STİL
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 10) // İkon ile başlık arasına boşluk
                    
                    // MARK: - Başlık
                    Text(isRegisterMode ? "Hesap Oluştur" : "Giriş Yap")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 20)
                    
                    // MARK: - Kayıt Modu (Sadece Kayıtta Görünür)
                    if isRegisterMode {
                        // "Ad Soyad" alanı
                        CustomTextField(iconName: "person.text.rectangle.fill",
                                        placeholder: "Ad Soyad",
                                        text: $fullName)
                        .textContentType(.name)
                        
                        // "Kullanıcı Adı" alanı
                        CustomTextField(iconName: "person.fill",
                                        placeholder: "Kullanıcı Adı",
                                        text: $username)
                        .textContentType(.username)
                    }
                    
                    // MARK: - Ortak Alanlar
                    CustomTextField(iconName: "envelope.fill",
                                    placeholder: "E-posta",
                                    text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    
                    CustomTextField(iconName: "lock.fill",
                                    placeholder: "Şifre",
                                    text: $password,
                                    isSecure: true) // <-- Burası önemli
                    .textContentType(isRegisterMode ? .newPassword : .password)
                    // MARK: - Ana Buton
                    Button(action: {
                        if isRegisterMode {
                            // Yeni register fonksiyonunu çağır
                            userVM.register(fullName: fullName,
                                            username: username,
                                            email: email,
                                            password: password)
                        } else {
                            // Yeni login fonksiyonunu çağır
                            userVM.login(email: email,
                                         password: password)
                        }
                    }) {
                        Text(isRegisterMode ? "Kayıt Ol" : "Giriş Yap")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    
                    Spacer() // Butonları yukarı iter
                    
                    // MARK: - Mod Değiştirme Butonu
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isRegisterMode.toggle() // Modu değiştir
                        }
                    }) {
                        HStack {
                            Text(isRegisterMode ? "Zaten bir hesabın var mı?" : "Hesabın yok mu?")
                            Text(isRegisterMode ? "Giriş Yap" : "Kayıt Ol")
                                .bold()
                        }
                        .font(.subheadline)
                    }
                    
                }
                .padding(.horizontal) // VStack'e kenar boşluğu
                .padding(.top, 30) // Üstten boşluk
            }
            .navigationDestination(isPresented: $userVM.isLoggedIn) {
                HomeView()
                    .environmentObject(userVM)
            }
        }
    }
    // MARK: - Özel Alan Bileşeni (Component)
    struct CustomTextField: View {
        var iconName: String
        var placeholder: String
        @Binding var text: String
        var isSecure: Bool = false // Şifre alanı mı?
        
        var body: some View {
            HStack(spacing: 15) {
                // İkon
                Image(systemName: iconName)
                    .font(.headline)
                    .frame(width: 20)
                    .foregroundColor(.black.opacity(0.6))
                
                // Alan
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) // Küçük bir gölge
        }
    }
}
#Preview {
    LoginView()
}
