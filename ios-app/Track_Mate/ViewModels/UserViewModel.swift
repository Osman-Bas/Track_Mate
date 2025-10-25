//
//  UserViewModel.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//
// ViewModels/UserViewModel.swift
import SwiftUI
internal import Combine

class UserViewModel: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var isLoggedIn: Bool = false
    
    func login(username: String, email: String) {
        self.currentUser = User(username: username, email: email, profileImage: "person.circle.fill")
        self.isLoggedIn = true
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
    }
}
