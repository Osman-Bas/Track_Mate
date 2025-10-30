const User = require('../models/User'); // Modelimizi import ediyoruz
const bcrypt = require('bcryptjs'); // Şifre hash'lemek için
const jwt = require('jsonwebtoken'); // Token oluşturmak için

//--- YENİ KULLANICI KAYDI (REGISTER) ---//
exports.registerUser = async (req, res) => {
    try {
        // 1. iOS'tan gelen veriyi al
        // (User.js modelimizde bu alanları "required" yaptık)
        const { fullName, username, email, password } = req.body;

        // 2. Gerekli alanlar boş mu? (Temel doğrulama)
        if (!fullName || !username || !email || !password) {
            return res.status(400).json({ msg: 'Lütfen tüm alanları doldurun.' });
        }

        // 3. E-posta adresi zaten kayıtlı mı?
        let userByEmail = await User.findOne({ email: email.toLowerCase() });
        if (userByEmail) {
            return res.status(400).json({ msg: 'Bu e-posta adresi zaten kullanılıyor.' });
        }

        // 4. Kullanıcı adı zaten alınmış mı?
        let userByUsername = await User.findOne({ username: username.toLowerCase() });
        if (userByUsername) {
            return res.status(400).json({ msg: 'Bu kullanıcı adı zaten alınmış.' });
        }

        // 5. Yeni kullanıcı nesnesini oluştur
        const newUser = new User({
            fullName,
            username: username.toLowerCase(),
            email: email.toLowerCase(),
            password // Henüz hash'lenmedi
        });

        // 6. ŞİFREYİ HASH'LEME (ÇOK ÖNEMLİ!)
        //    Şifreyi asla düz metin olarak kaydetmeyin.
        const salt = await bcrypt.genSalt(10); // Güvenlik katmanı
        newUser.password = await bcrypt.hash(password, salt);

        // 7. Kullanıcıyı veritabanına kaydet
        await newUser.save();

        // 8. Başarılı kayıt sonrası iOS'a bir "token" gönderelim
        //    Böylece kullanıcı kayıt olur olmaz giriş yapmış olur.
        const payload = {
            user: {
                id: newUser.id // Token içine kullanıcının benzersiz DB ID'sini koy
            }
        };

        // .env dosyanızdaki gizli anahtarı kullan
        jwt.sign(
            payload,
            process.env.JWT_SECRET, // (Bunu .env dosyanıza eklemelisiniz!)
            { expiresIn: '30d' },   // Token 30 gün geçerli olsun
            (err, token) => {
                if (err) throw err;
                // 9. Token'ı iOS uygulamasına geri gönder
                res.status(201).json({ token }); // 201 = "Created"
            }
        );

    } catch (err) {
        console.error('Register Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};


//--- KULLANICI GİRİŞİ (LOGIN) ---//
exports.loginUser = async (req, res) => {
    try {
        // 1. iOS'tan gelen veriyi al
        const { email, password } = req.body;

        // 2. Gerekli alanlar boş mu?
        if (!email || !password) {
            return res.status(400).json({ msg: 'Lütfen tüm alanları doldurun.' });
        }

        // 3. Kullanıcı var mı? (E-postaya göre bul)
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            // Güvenlik için "e-posta bulunamadı" demek yerine genel bir hata ver
            return res.status(400).json({ msg: 'Geçersiz e-posta veya şifre.' });
        }

        // 4. Şifreler eşleşiyor mu?
        //    (bcrypt, gelen şifreyi veritabanındaki hash'lenmiş şifreyle karşılaştırır)
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(400).json({ msg: 'Geçersiz e-posta veya şifre.' });
        }

        // 5. GİRİŞ BAŞARILI: JSON WEB TOKEN (JWT) OLUŞTUR
        const payload = {
            user: {
                id: user.id
            }
        };

        // 6. Token'ı imzala ve iOS'a gönder
        jwt.sign(
            payload,
            process.env.JWT_SECRET, // (Bunu .env dosyanıza eklemelisiniz!)
            { expiresIn: '30d' },
            (err, token) => {
                if (err) throw err;
                res.json({ token }); // Giriş başarılı, token gönderildi.
            }
        );

    } catch (err) {
        console.error('Login Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};
