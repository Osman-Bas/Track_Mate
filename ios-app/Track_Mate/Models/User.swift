//
//  User.swift
//  Track_Mate
//
//  Created by Osman Baş on 2.10.2025.
//
import Foundation

struct User: Codable {
    var id: String?
    var fullName: String
    var username: String
    var email: String
    var profilePictureUrl: String? // system image adı veya url olabilir
    
    enum CodingKeys: String, CodingKey {
        case id = "_id" // JSON'daki "_id"yi, struct'ımızdaki "id"ye ata
        case fullName
        case username
        case email
        case profilePictureUrl
    }
}


