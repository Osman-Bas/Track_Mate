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
    var profilePictureUrl: String?
    
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case username
        case email
        case profilePictureUrl
    }
}


