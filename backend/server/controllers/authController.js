// 'require' yerine 'import' kullanıyoruz
import User from '../models/User.js'; // Modelimizi import ediyoruz (.js uzantısı ESM için önemli)
import bcrypt from 'bcryptjs'; // Şifre hash'lemek için
import jwt from 'jsonwebtoken'; // Token oluşturmak için
import { validationResult } from 'express-validator'; // Rotalardaki 'check' sonuçlarını yakalamak için

//--- YENİ KULLANICI KAYDI (REGISTER) ---//
// 'exports.registerUser' yerine 'export const' kullanıyoruz
export const registerUser = async (req, res) => {
    // 1. Rota'daki (authRoutes.js) doğrulama kontrollerinin sonucunu yakala
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        // Eğer 'check' fonksiyonlarından birinde hata varsa (örn: email geçersiz)
        // iOS'a ilk hatayı mesaj olarak gönder.
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        // 2. iOS'tan gelen veriyi al
        const { fullName, username, email, password } = req.body;

        // 3. E-posta adresi zaten kayıtlı mı?
        // (Doğrulamayı geçtiğimiz için email/username'in dolu olduğunu biliyoruz)
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

        // 6. ŞİFREYİ HASH'LEME
        const salt = await bcrypt.genSalt(10);
        newUser.password = await bcrypt.hash(password, salt);

        // 7. Kullanıcıyı veritabanına kaydet
        await newUser.save();

        // 8. Başarılı kayıt sonrası iOS'a bir "token" gönder
        const payload = {
            user: {
                id: newUser.id
            }
        };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '30d' },
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
// 'exports.loginUser' yerine 'export const' kullanıyoruz
export const loginUser = async (req, res) => {
    // 1. Rota'daki doğrulama kontrollerinin sonucunu yakala
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        // 2. iOS'tan gelen veriyi al
        const { email, password } = req.body;

        // 3. Kullanıcı var mı? (E-postaya göre bul)
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            return res.status(400).json({ msg: 'Geçersiz e-posta veya şifre.' });
        }

        // 4. Şifreler eşleşiyor mu?
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
            process.env.JWT_SECRET,
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

