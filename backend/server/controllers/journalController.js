import JournalEntry from '../models/JournalEntry.js'; // 1. Adımda oluşturduğumuz modeli import et
import { validationResult } from 'express-validator';

// --- 1. YENİ GÜNLÜK KAYDI OLUŞTUR ---
// @route   POST /api/journal
// @desc    Yeni bir günlük kaydı (mood + journal metni) oluştur
// @access  Private (authMiddleware ile korunacak)
export const createJournalEntry = async (req, res) => {
    // Rota'da (Adım 2.2.B'de) ekleyeceğimiz doğrulama kurallarını kontrol et
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        // 1. iOS'tan (Gün sonu ekranı) gelen verileri al
        const { mood, journal } = req.body;

        // 2. Yeni bir JournalEntry nesnesi oluştur
        //    'user' alanını, 'authMiddleware'den gelen 'req.user.id'
        //    (giriş yapmış kullanıcının ID'si) ile doldur.
        const newEntry = new JournalEntry({
            user: req.user.id, // Bu kaydın sahibini belirle
            mood,
            journal
        });

        // 3. Günlük kaydını veritabanına kaydet
        const entry = await newEntry.save();

        // 4. Planda belirtildiği gibi, yeni oluşturulan kaydı
        //    (ID'si ve 'createdAt' tarihiyle birlikte) iOS'a geri gönder.
        res.status(201).json(entry); // 201 = Created

    } catch (err) {
        console.error('createJournalEntry Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};

export const getMyJournalEntries = async (req, res) => {
    try {
        // Veritabanında 'user' alanı, giriş yapmış kullanıcının ID'si
        // ('req.user.id') ile eşleşen TÜM kayıtları bul.
        // Planda istendiği gibi, en yeniden en eskiye doğru sırala ('createdAt: -1').
        const entries = await JournalEntry.find({ user: req.user.id }).sort({ createdAt: -1 });

        // Günlük kaydı dizisini (array) iOS'a gönder
        res.json(entries);

    } catch (err) {
        console.error('getMyJournalEntries Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};