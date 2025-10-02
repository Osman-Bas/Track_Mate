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
    @State private var email: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("TrackMate")
                    .font(.largeTitle.bold())
                
                TextField("Kullanıcı Adı", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("E-posta", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Giriş Yap") {
                    userVM.login(username: username, email: email)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
            // iOS 16+ uyumlu navigationDestination kullanımı
            .navigationDestination(isPresented: $userVM.isLoggedIn) {
                HomeView()
                    .environmentObject(userVM)
            }
        }
    }
}
