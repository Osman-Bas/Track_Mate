/*
 * Gelişmiş Veri Tohumlama (Database Seeder) Script'i (v3 - Kişisel)
 * * Amaç: AI'ın 'journal' metinlerindeki kişisel *nedenlere*
 * nasıl tepki verdiğini test etmek.
 * * NASIL ÇALIŞTIRILIR (Terminalde server/ klasöründeyken):
 * * 1. "Stresli Öğrenci" Senaryosu:
 * node seed.js stressed_school
 *
 * 2. "Stresli Çalışan" Senaryosu:
 * node seed.js stressed_work
 *
 * 3. "Üretken/Mutlu Kullanıcı" Senaryosu:
 * node seed.js productive
 */

import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

import connectDB from './configs/db.js';
import User from './models/User.js';
import Task from './models/Task.js';
import JournalEntry from './models/JournalEntry.js';

// --- Sabitler ---
const TASK_PRIORITIES = ['Düşük', 'Orta', 'Yüksek'];
const MOODS = ['berbat', 'uzgun', 'normal', 'mutlu', 'harika'];

// --- GÜNCELLEME 1: ÇOK DAHA KİŞİSEL GÜNLÜK METİNLERİ ---
// (Artık sadece 'bunalmış' demiyor, 'neden'ini söylüyoruz)
const STRESSED_JOURNALS_WORK = [ // İŞ TEMALI
    "Bugünkü sunum berbattı, proje yetişmeyecek gibi hissediyorum.",
    "Patronumla tartıştım, motivasyonum sıfır.",
    "Yarınki toplantı için çok stresliyim, sunumu hazırlamadım."
];
const STRESSED_JOURNALS_SCHOOL = [ // OKUL TEMALI
    "Final haftası çok yorucu, 3 sınavım daha var.",
    "Matematik vizesinden kaldım, moralim çok bozuk.",
    "Tezimi yetiştiremeyeceğim diye çok korkuyorum."
];
const PRODUCTIVE_JOURNALS = [ // ÜRETKEN TEMALI
    "Bugün harika bir gündü, çok iş bitirdim.",
    "İyi bir rutin yakaladım, enerji doluyum.",
    "Zor bir görevi tamamladım, kendimle gurur duyuyorum."
];

// --- Yardımcı Fonksiyonlar ---
const getRandomItem = (arr) => arr[Math.floor(Math.random() * arr.length)];
const getRandomPastDate = (days = 7) => {
    const date = new Date();
    date.setDate(date.getDate() - Math.floor(Math.random() * days));
    return date;
};

// --- Ana Tohumlama Fonksiyonu ---
const seedDatabase = async () => {
    // 1. HANGİ SENARYO?
    // Artık 3 senaryomuz var (stressed_work, stressed_school, productive)
    const scenario = process.argv[2] || 'stressed_work'; // Varsayılan: iş stresi

    if (!['stressed_work', 'stressed_school', 'productive'].includes(scenario)) {
        console.error('HATA: Geçersiz senaryo.');
        console.log('Lütfen "stressed_work", "stressed_school" veya "productive" kullanın.');
        return;
    }

    try {
        console.log('Veritabanına bağlanılıyor...');
        await connectDB();
        console.log('Veritabanına bağlandı.');

        // 2. HANGİ KULLANICI? (EN YENİ KAYDOLAN)
        const user = await User.findOne().sort({ createdAt: -1 });

        if (!user) {
            console.error('HATA: Veritabanında hiçbir kullanıcı bulunamadı.');
            return;
        }

        console.log(`\n--- SENARYO: "${scenario}" ---`);
        console.log(`Hedef kullanıcı: "${user.username}" (${user.email})`);

        // 3. TEMİZLİK: Bu kullanıcıya ait ESKİ verileri SİL
        await Task.deleteMany({ user: user._id });
        await JournalEntry.deleteMany({ user: user._id });
        console.log('Eski test verileri temizlendi.');

        const taskPromises = [];
        const journalPromises = [];
        let moodToSet = 'normal'; // Varsayılan anlık ruh hali

        // --- 4A. "Stresli" Senaryo Kurulumu (İş veya Okul) ---
        if (scenario.startsWith('stressed')) {
            moodToSet = 'uzgun';
            const journalSet = (scenario === 'stressed_work') ? STRESSED_JOURNALS_WORK : STRESSED_JOURNALS_SCHOOL;
            const taskTitlePrefix = (scenario === 'stressed_work') ? "(İş Stresi)" : "(Okul Stresi)";

            console.log(`"${scenario}" verisi oluşturuluyor...`);
            
            // GÖREVLER (5 adet BİTMEMİŞ YÜKSEK öncelikli)
            for (let i = 0; i < 5; i++) {
                taskPromises.push(new Task({
                    user: user._id,
                    title: `${taskTitlePrefix} Acil Görev ${i + 1}`,
                    isCompleted: false,
                    priority: 'Yüksek',
                    createdAt: getRandomPastDate(2)
                }).save());
            }

            // GÜNLÜKLER (Spesifik metinler içeren 3 negatif kayıt)
            for (let i = 0; i < 3; i++) {
                journalPromises.push(new JournalEntry({
                    user: user._id,
                    mood: getRandomItem(['uzgun', 'berbat']),
                    journal: getRandomItem(journalSet), // KİŞİSEL METİN BURADA
                    createdAt: getRandomPastDate(7)
                }).save());
            }
        }

        // --- 4B. "Üretken" Senaryo Kurulumu ---
        if (scenario === 'productive') {
            moodToSet = 'mutlu';
            console.log('"Üretken Kullanıcı" verisi oluşturuluyor...');
            
            // GÖREVLER (15 adet, çoğu tamamlanmış)
            for (let i = 0; i < 15; i++) {
                taskPromises.push(new Task({
                    user: user._id,
                    title: `(Üretken Test) Görev ${i + 1}`,
                    isCompleted: Math.random() > 0.2, // %80'i tamamlanmış
                    priority: getRandomItem(TASK_PRIORITIES),
                    createdAt: getRandomPastDate(7)
                }).save());
            }

            // GÜNLÜKLER (Spesifik metinler içeren 3 pozitif kayıt)
            for (let i = 0; i < 3; i++) {
                journalPromises.push(new JournalEntry({
                    user: user._id,
                    mood: getRandomItem(['mutlu', 'harika']),
                    journal: getRandomItem(PRODUCTIVE_JOURNALS), // KİŞİSEL METİN BURADA
                    createdAt: getRandomPastDate(7)
                }).save());
            }
        }
        
        // 5. ANLIK RUH HALİNİ (currentMood) AYARLA
        await User.findByIdAndUpdate(user._id, { currentMood: moodToSet });

        // 6. Tüm verilerin kaydedilmesini bekle
        await Promise.all(taskPromises);
        await Promise.all(journalPromises);

        console.log(`✅ ${taskPromises.length} adet sahte GÖREV oluşturuldu.`);
        console.log(`✅ ${journalPromises.length} adet sahte GÜNLÜK kaydı oluşturuldu.`);
        console.log(`✅ Kullanıcının anlık ruh hali (currentMood) -> "${moodToSet}" olarak ayarlandı.`);

        console.log('\n--- Tohumlama (Seeding) Başarıyla Tamamlandı! ---');

    } catch (err) {
        console.error('Tohumlama sırasında bir hata oluştu:', err.message);
    } finally {
        await mongoose.disconnect();
        console.log('Veritabanı bağlantısı kapatıldı.');
    }
};

// Script'i çalıştır
seedDatabase();