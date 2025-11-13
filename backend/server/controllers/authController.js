// Gerekli paketleri import et
import User from '../models/User.js'; // Modelimiz (.js uzantısı önemli)
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { validationResult } from 'express-validator'; // Doğrulama için

//--- YENİ KULLANICI KAYDI (REGISTER) ---//
export const registerUser = async (req, res) => {
    // Rota'daki 'check' kontrollerinden gelen hataları yakala
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        const { fullName, username, email, password } = req.body;

        // E-posta ve kullanıcı adı kontrolü
        let userByEmail = await User.findOne({ email: email.toLowerCase() });
        if (userByEmail) {
            return res.status(400).json({ msg: 'Bu e-posta adresi zaten kullanılıyor.' });
        }
        let userByUsername = await User.findOne({ username: username.toLowerCase() });
        if (userByUsername) {
            return res.status(400).json({ msg: 'Bu kullanıcı adı zaten alınmış.' });
        }

        // Yeni kullanıcı oluştur
        const newUser = new User({
            fullName,
            username: username.toLowerCase(),
            email: email.toLowerCase(),
            password
        });

        // Şifreyi hash'le
        const salt = await bcrypt.genSalt(10);
        newUser.password = await bcrypt.hash(password, salt);

        // Kullanıcıyı kaydet
        await newUser.save();

        // Token oluştur
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
                res.status(201).json({ token }); // 201 = Created
            }
        );

    } catch (err) {
        console.error('Register Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};

//--- KULLANICI GİRİŞİ (LOGIN) ---//
export const loginUser = async (req, res) => {
    // Rota'daki 'check' kontrollerinden gelen hataları yakala
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        const { email, password } = req.body;

        // Kullanıcıyı bul
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            return res.status(400).json({ msg: 'Geçersiz e-posta veya şifre.' });
        }

        // Şifreyi karşılaştır
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Geçersiz e-posta veya şifre.' });
        }

        // Token oluştur
        const payload = {
            user: {
                id: user.id
            }
        };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '30d' },
            (err, token) => {
                if (err) throw err;
                res.json({ token });
            }
        );

    } catch (err) {
        console.error('Login Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};


// @desc    Giriş yapmış kullanıcının bilgilerini al ("Ben Kimim?")
// @route   GET /api/auth/me
// @access  Private (authMiddleware tarafından korunuyor)
export const getMe = async (req, res) => {
    try {
        // 1. Token doğrulandı ve 'authMiddleware' çalıştı.
        // 2. Middleware, 'req.user' içine token'dan gelen { id: ... } bilgisini ekledi.

        // 3. Veritabanından kullanıcıyı ID ile bul.
        //    '.select('-password')' komutu, şifre HARİÇ DİĞER TÜM BİLGİLERİ getirmemizi sağlar.
        const user = await User.findById(req.user.id).select('-password');

        if (!user) {
            return res.status(404).json({ msg: 'Kullanıcı bulunamadı.' });
        }

        // 4. Kullanıcı bilgilerini (şifre hariç) iOS uygulamasına gönder.
        //    iOS'taki DashboardView'un (user.username) bu bilgiye ihtiyacı var.
        res.json(user);

    } catch (err) {
        console.error('getMe Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};

export const updateMood = async (req, res) => {
    // 1. Rota'dan (authRoutes.js) gelen doğrulama sonucunu kontrol et
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        // 2. iOS'tan gelen yeni 'mood' değerini al
        const { mood } = req.body;

        // 3. Kullanıcıyı, 'authMiddleware' sayesinde 'req.user.id'den bul
        //    ve 'currentMood' alanını güncelle.
        //    { new: true } -> güncellenmiş (yeni) kullanıcı verisini döndürür.
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { currentMood: mood },
            { new: true, runValidators: true } // 'runValidators' enum kontrolünü tetikler
        ).select('currentMood'); // Sadece güncellenen alanı geri döndür

        if (!user) {
            return res.status(404).json({ msg: 'Kullanıcı bulunamadı.' });
        }

        // 4. Planda belirtildiği gibi başarı cevabını döndür.
        res.json({ success: true, newMood: user.currentMood });

    } catch (err) {
        console.error('updateMood Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};