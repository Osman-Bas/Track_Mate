//
//  User.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//
import Foundation

struct User {
    var id: UUID = UUID()
    var username: String
    var email: String
    var profileImage: String? // system image adı veya url olabilir
}
