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
    @Published var authToken: String? = nil
    @Published var isLoggedIn: Bool = false
    // MARK: - API Adresleri
    private let apiBaseURL = "http://192.168.8.196:3000"
    
    // GİRİŞ YAP FONKSİYONU (Ağ isteği eklendi)
    func login(email: String, password: String) {
        
        // 1. Gidecek Adres (URL) nedir?
        // Bu sefer '/api/auth/login' adresini kullanıyoruz
        let urlString = "\(apiBaseURL)/api/auth/login"
        
        guard let url = URL(string: urlString) else {
            print("Hata: Geçersiz login URL'i")
            // TODO: Kullanıcıya "Geçersiz URL" hatası göster
            return
        }
        
        // 2. Gidecek Veri (JSON Body) nedir?
        // Backend'in /login için beklediği JSON (sadece email ve password)
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        guard let jsonData = try? JSONEncoder().encode(body) else {
            print("Hata: JSON encode edilemedi")
            return
        }
        
        // 3. İsteği (Request) Hazırlamak
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        
        // 4. İsteği Göndermek (URLSession)
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 5. Cevabı (Response) İşlemek
            if let error = error {
                print("Ağ Hatası: \(error.localizedDescription)")
                // TODO: Kullanıcıya "İnternet bağlantınızı kontrol edin" hatası göster
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Geçersiz Cevap")
                return
            }
            
            guard let data = data else {
                print("Veri gelmedi")
                return
            }
            
            DispatchQueue.main.async { // UI güncellemeleri ANA THREAD'de yapılmalı
                do {
                    // Backend koduna göre, BAŞARILI GİRİŞ '200' kodu göndermeli
                    // (register 201 gönderiyordu, login genellikle 200 gönderir)
                    if httpResponse.statusCode == 200 { // 200 = Başarılı Giriş
                        
                        struct TokenResponse: Codable {
                            let token: String
                        }
                        
                        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                        print("Başarılı Giriş! Token alındı, şimdi kullanıcı bilgisi çekilecek...")
                        
                        // ---- YENİ ADIMLAR ----
                        // 1. Token'ı ViewModel'e kaydet
                        self.authToken = tokenResponse.token
                        
                        // 2. 'isLoggedIn = true' YAPMA.
                        //    Onun yerine, kullanıcıyı getirmesi için 'getMe()'yi çağır.
                        self.getMe()
                        // ------------------------
                        
                    } else if httpResponse.statusCode == 400 { // 400 = Kullanıcı Hatası
                        
                        struct ErrorResponse: Codable {
                            let msg: String
                        }
                        
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        print("Giriş Hatası: \(errorResponse.msg)")
                        
                        // TODO: Kullanıcıya bu 'errorResponse.msg'i bir Alert ile göster
                        
                    } else {
                        // Diğer (500 vb.) sunucu hataları
                        print("Sunucu Hatası. Kod: \(httpResponse.statusCode)")
                    }
                } catch {
                    print("JSON Decode Hatası: \(error)")
                }
            }
            
        }.resume() // <-- İsteği resmen başlatır
    }
    
    
    // KAYIT OL FONKSİYONU (Ağ isteği eklendi)
    func register(fullName: String, username: String, email: String, password: String) {
        
        // 1. Gidecek Adres (URL) nedir?
        // Önce adresin String halini oluşturuyoruz
        let urlString = "\(apiBaseURL)/api/auth/register"
        
        // Bu String'i gerçek bir URL nesnesine çeviriyoruz
        guard let url = URL(string: urlString) else {
            print("Hata: Geçersiz register URL'i")
            // TODO: Kullanıcıya "Geçersiz URL" hatası göster
            return
        }
        
        // 2. Gidecek Veri (JSON Body) nedir?
        // Backend'in beklediği JSON'a uyması için bir 'struct' kullanıyoruz.
        // NOT: Bu struct'ı UserViewModel'in DIŞINA veya ayrı bir dosyaya koymak daha iyidir.
        // Şimdilik kolaylık olması için buraya ekliyoruz, ama hataya sebep olabilir.
        // En iyisi, bu struct'ı User.swift dosyasının içine ekleyelim.
        
        // --- BU ADIMI ATLA, DÜZELTECEĞİZ ---
        // Şimdilik manuel bir dictionary (sözlük) oluşturalım:
        let body: [String: String] = [
            "fullName": fullName,
            "username": username,
            "email": email,
            "password": password
        ]
        
        // Bu sözlüğü JSON verisine çeviriyoruz (Data)
        guard let jsonData = try? JSONEncoder().encode(body) else {
            print("Hata: JSON encode edilemedi")
            return
        }
        
        
        // 3. İsteği (Request) Hazırlamak
        var request = URLRequest(url: url)
        
        // Method: Backend kodu (router.post) "POST" bekliyordu
        request.httpMethod = "POST"
        
        // Header: "Ben sana JSON gönderiyorum" diyoruz
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Body: Hazırladığımız JSON verisini isteğe ekliyoruz
        request.httpBody = jsonData
        
        
        // 4. İsteği Göndermek (URLSession)
        // URLSession.shared.dataTask, ağ isteğini yapan asıl komuttur.
        // 'data', 'response', 'error' olmak üzere 3 şey döner.
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 5. Cevabı (Response) İşlemek
            
            // A. Önce bir ağ hatası (internet yok vb.) oldu mu?
            if let error = error {
                print("Ağ Hatası: \(error.localizedDescription)")
                // TODO: Kullanıcıya "İnternet bağlantınızı kontrol edin" hatası göster
                return
            }
            
            // B. Gelen cevap geçerli bir HTTP cevabı mı?
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Geçersiz Cevap")
                return
            }
            
            // C. HTTP Durum Kodu (Status Code) nedir?
            // Backend koduna göre (res.status(201)...), başarılı kayıt '201' göndermeli.
            // Backend koduna göre (res.status(400)...), hatalar (e-posta kullanımda vb.) '400' göndermeli.
            
            guard let data = data else {
                print("Veri gelmedi")
                return
            }
            
            DispatchQueue.main.async { // <-- UI güncellemeleri ANA THREAD'de yapılmalı
                do {
                    if httpResponse.statusCode == 201 { // 201 = Başarılı Kayıt
                        
                        struct TokenResponse: Codable {
                            let token: String
                        }
                        
                        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                        print("Başarılı Kayıt! Token alındı, şimdi kullanıcı bilgisi çekilecek...")
                        
                        // ---- YENİ ADIMLAR ----
                        // 1. Token'ı ViewModel'e kaydet
                        self.authToken = tokenResponse.token
                        
                        // 2. 'isLoggedIn = true' YAPMA.
                        //    Onun yerine, kullanıcıyı getirmesi için 'getMe()'yi çağır.
                        self.getMe()
                        // ------------------------
                        
                    } else if httpResponse.statusCode == 400 { // 400 = Kullanıcı Hatası
                        
                        struct ErrorResponse: Codable {
                            let msg: String
                        }
                        
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        print("Kayıt Hatası: \(errorResponse.msg)")
                        
                        // TODO: Kullanıcıya bu 'errorResponse.msg'i bir Alert ile göster
                        
                    } else {
                        // Diğer (500 vb.) sunucu hataları
                        print("Sunucu Hatası. Kod: \(httpResponse.statusCode)")
                    }
                } catch {
                    print("JSON Decode Hatası: \(error)")
                }
            }
            
        }.resume() // <-- İsteği resmen başlatır (Bunu asla unutma!)
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
    }
    //--- KULLANICI BİLGİSİNİ GETİR ---//
    func getMe() {
        
        // 1. Token (authToken) var mı? (Giriş yapılmış mı?)
        guard let token = authToken else {
            print("Hata: Token 'nil'. getMe() çağrılamaz.")
            return
        }
        
        // 2. Gidecek Adres (URL) nedir?
        // Sude'nin /api/auth/me adresini kullanıyoruz
        let urlString = "\(apiBaseURL)/api/auth/me"
        
        guard let url = URL(string: urlString) else {
            print("Hata: Geçersiz getMe URL'i")
            return
        }
        
        // 3. İsteği (Request) Hazırlamak
        var request = URLRequest(url: url)
        
        // Method: Sude'nin kodu (router.get) "GET" bekliyordu
        request.httpMethod = "GET"
        
        // HEADER (EN ÖNEMLİ KISIM):
        // Sude'nin 'authMiddleware' kodu, "Bearer <token>" formatında
        // bir 'Authorization' başlığı bekliyordu.
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        // 4. İsteği Göndermek (URLSession)
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 5. Cevabı (Response) İşlemek
            if let error = error {
                print("Ağ Hatası (getMe): \(error.localizedDescription)")
                // TODO: Hata göster
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Geçersiz Cevap (getMe)")
                return
            }
            
            guard let data = data else {
                print("Veri gelmedi (getMe)")
                return
            }
            
            DispatchQueue.main.async { // UI güncellemeleri ANA THREAD'de yapılmalı
                do {
                    // Sude'nin kodu 'res.json(user)' ile 200 kodu gönderiyor
                    if httpResponse.statusCode == 200 {
                        
                        // Backend'den tam bir 'User' objesi geliyor.
                        // Bizim 'User.swift' modelimiz (Codable ve CodingKeys ile)
                        // bu JSON'u doğrudan çözebilir.
                        let user = try JSONDecoder().decode(User.self, from: data)
                        
                        // ---- İŞTE BAŞARDIK! ----
                        self.currentUser = user // <-- 1. Kullanıcıyı atadık
                        self.isLoggedIn = true  // <-- 2. Ana ekrana geçişi tetikledik
                        // ------------------------
                        
                        print("Kullanıcı başarıyla getirildi: \(user.username)")
                        
                    } else if httpResponse.statusCode == 401 { // 401 = Yetki Yok
                        print("Giriş Hatası (getMe): Token geçersiz veya süresi dolmuş.")
                        // TODO: Kullanıcıyı login ekranına at (logout)
                        
                    } else {
                        print("Sunucu Hatası (getMe). Kod: \(httpResponse.statusCode)")
                    }
                } catch {
                    print("JSON Decode Hatası (getMe): \(error)")
                }
            }
            
        }.resume() // <-- İsteği resmen başlatır
    }
   

}
