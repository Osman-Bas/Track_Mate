//
//  KeychainService.swift
//  Track_Mate
//
//  Created by Osman Baş on 8.11.2025.
//

import Foundation
import Security // <-- Apple'ın Güvenlik Kütüphanesi

/*
 BU YARDIMCI DOSYANIN GÖREVİ:
 -----------------------------
 Bu dosya, uygulamamızın "kasasıdır". Backend'den aldığımız 'JWT Token'ını,
 telefonun şifrelenmiş hafızası olan 'Keychain'e (Anahtar Zinciri)
 güvenli bir şekilde kaydeder, oradan okur ve oradan siler.

 Neden 'UserDefault' değil de 'Keychain'?
 'UserDefault' verileri şifrelemez ve herkes tarafından okunabilir.
 'Keychain' ise Apple tarafından donanımsal olarak şifrelenir ve
 biyometrik (Face ID/Touch ID) koruma altına alınabilir.
 API Token'ları 'Keychain'de saklanmak zorundadır.
*/

struct KeychainService {
    
    // Token'ı kaydetmek için benzersiz bir anahtar (key)
    // Bu, "kasadaki" verimizin etiketidir.
    private static let service = "com.TrackMate.auth" // Uygulamanızın kimliği
    private static let account = "userToken"          // Kaydettiğimiz verinin adı
    
    // MARK: - 1. Token'ı Güvenle Kaydet
    
    static func save(token: String) {
        // Token'ımızı (String) önce Data formatına çevirmeliyiz
        guard let data = token.data(using: .utf8) else {
            print("Keychain: Token Data'ya çevrilemedi")
            return
        }
        
        // 1. Sorgu (Query) Hazırla: Neyi, nereye kaydedeceğiz?
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // Tür: Genel bir şifre
            kSecAttrService as String: service,            // Etiket 1: Hangi servis?
            kSecAttrAccount as String: account,            // Etiket 2: Hangi hesap?
            kSecValueData as String: data                  // Değer: Kaydedilecek veri (token)
        ]
        
        // 2. Önce eski kaydı silmeye çalış (varsa)
        // Keychain'de "update" (güncelle) işlemi, önce "delete" (sil) sonra "add" (ekle)
        // yapmakla aynıdır ve daha güvenlidir.
        SecItemDelete(query as CFDictionary)
        
        // 3. Yeni veriyi ekle
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // 4. Durumu kontrol et
        if status == errSecSuccess {
            print("Keychain: Token başarıyla kaydedildi.")
        } else if let error = SecCopyErrorMessageString(status, nil) {
            print("Keychain: Kaydetme hatası - \(error)")
        }
    }
    
    // MARK: - 2. Token'ı Güvenle Oku
    
    static func readToken() -> String? {
        
        // 1. Sorgu Hazırla: Neyi arıyoruz?
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,    // Bize veriyi (Data) geri döndür
            kSecMatchLimit as String: kSecMatchLimitOne   // Sadece bir tane bul
        ]
        
        var dataTypeRef: AnyObject? // Dönen veriyi tutacak referans
        
        // 2. Keychain'de arama yap
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        // 3. Durumu kontrol et
        if status == errSecSuccess {
            // Başarılı: Veri bulundu
            guard let data = dataTypeRef as? Data else {
                print("Keychain: Veri bulundu ama Data formatında değil")
                return nil
            }
            
            // Bulduğumuz Data'yı tekrar String'e (Token) çevir
            guard let token = String(data: data, encoding: .utf8) else {
                print("Keychain: Data, String'e (UTF8) çevrilemedi")
                return nil
            }
            
            print("Keychain: Token başarıyla okundu.")
            return token
            
        } else {
            // Başarısız: Veri bulunamadı (nil dön)
            print("Keychain: Token bulunamadı (errSecItemNotFound olabilir).")
            return nil
        }
    }
    
    // MARK: - 3. Token'ı Güvenle Sil (Logout)
    
    static func deleteToken() {
        
        // 1. Sorgu Hazırla: Neyi sileceğiz?
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // 2. Silme işlemini yap
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("Keychain: Token başarıyla silindi (Logout).")
        } else if let error = SecCopyErrorMessageString(status, nil) {
            print("Keychain: Silme hatası - \(error)")
        }
    }
}
