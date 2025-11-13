/*
 * VERİ TOHUMLAMA (DATABASE SEEDER) SCRIPT'İ (GÜNCELLENMİŞ VERSİYON)
 * * Amaç: İstatistik (StatsView) sayfasını test etmek için
 * veritabanını SON 20 GÜNE YAYILMIŞ sahte verilerle doldurmak.
 * * Nasıl Çalıştırılır:
 * 1. Sunucunuzun (npm run server) çalışmasına GEREK YOK.
 * 2. Terminalde (server/ klasöründeyken):
 * node seed.js
 */

import mongoose from 'mongoose';
// 'dotenv' paketini kullanarak .env dosyasını manuel okuyoruz (Node versiyonu bağımsız)
import dotenv from 'dotenv'; 
dotenv.config(); 

import connectDB from './configs/db.js'; // DB bağlantı fonksiyonumuz

// Modellerimizi import ediyoruz
import User from './models/User.js';
import Task from './models/Task.js';
import JournalEntry from './models/JournalEntry.js';

// --- Sahte Veri Tanımları ---

// Task.js modelimizdeki 'enum' ile EŞLEŞMELİ
const TASK_PRIORITIES = ['Düşük', 'Orta', 'Yüksek']; 

// JournalEntry.js modelimizdeki 'enum' ile EŞLEŞMELİ
const MOODS = ['berbat', 'uzgun', 'normal', 'mutlu', 'harika'];

const SAMPLE_TASKS = [
    "Track_Mate UI tasarımını bitir", "StatsView API'sini test et", "iOS bug'larını düzelt",
    "Sunucuyu deploy et", "Haftalık toplantı notlarını hazırla", "Veritabanı yedeğini al",
    "Auth rotalarını gözden geçir", "Yeni özellikleri planla", "Kullanıcı geri bildirimlerini analiz et"
];

const SAMPLE_JOURNALS = [
    "Bugün çok verimli geçti, istatistik API'si tamamlandı.",
    "Biraz yorgun hissediyorum, kahve molası şart.",
    "iOS simülatöründe garip bir hata aldım, yarın bakacağım.",
    "Motivasyonum yüksek, yeni özelliklara hazırım.",
    "Kodlama yaparken zamanın nasıl geçtiğini anlamadım."
];

// --- Yardımcı Fonksiyonlar ---

// Bir diziden rastgele bir eleman seçer
const getRandomItem = (arr) => arr[Math.floor(Math.random() * arr.length)];

// (Eski 'getRandomPastDate' fonksiyonunu kaldırdık, çünkü artık yapısal ilerleyeceğiz)


// --- Ana Tohumlama Fonksiyonu ---
const seedDatabase = async () => {
    try {
        console.log('Veritabanına bağlanılıyor...');
        await connectDB(); // db.js'deki fonksiyonumuzla bağlan
        console.log('Veritabanına bağlandı.');

        // 1. BU VERİLERİ KİME ATAYACAĞIZ?
        //    (Test için kaydolmuş) ilk kullanıcıyı bul.
        const user = await User.findOne();

        if (!user) {
            console.error('HATA: Veritabanında en az bir kayıtlı kullanıcı bulunamadı.');
            console.log('Lütfen önce test için bir kullanıcı kaydı (register) yapın.');
            return;
        }

        console.log(`Veriler "${user.username}" (${user.email}) kullanıcısına atanacak...`);

        // 2. TEMİZLİK: Bu kullanıcıya ait ESKİ görevleri ve günlükleri SİL
        await Task.deleteMany({ user: user._id });
        await JournalEntry.deleteMany({ user: user._id });
        console.log('Eski test verileri temizlendi.');

        // --- YENİ YAPI (GÜNCELLENDİ) ---
        // 'totalDays' gün geriye giderek her güne 'tasksPerDay' görev ekle
        
        const taskPromises = [];
        const journalPromises = [];
        const totalDaysToSeed = 20; // Son 20 gün
        const tasksPerDay = 4; // Her gün için 4 görev (Toplam 80 görev)

        console.log(`Geçmiş ${totalDaysToSeed} gün için sahte veri oluşturuluyor...`);

        for (let day = 0; day < totalDaysToSeed; day++) {
            
            // 1. O GÜNÜN TARİHİNİ HESAPLA (day=0 'bugün', day=1 'dün'...)
            const specificDate = new Date();
            specificDate.setDate(specificDate.getDate() - day); // 'day' gün geriye git
            // Görevlerin/Günlüklerin gün içinde rastgele bir saatte oluşturulması için:
            specificDate.setHours(
                Math.floor(Math.random() * 10) + 9, // Sabah 9 ile akşam 7 (19) arası
                Math.floor(Math.random() * 60)
            );

            // 2. O GÜN İÇİN 'tasksPerDay' ADET GÖREV OLUŞTUR
            for (let i = 0; i < tasksPerDay; i++) {
                const isCompleted = Math.random() > 0.3; // %70'i tamamlanmış olsun
                
                const task = new Task({
                    user: user._id,
                    title: `${getRandomItem(SAMPLE_TASKS)} (Gün ${day}, Görev ${i+1})`,
                    description: "Bu, seeder script tarafından oluşturulmuş bir test görevidir.",
                    priority: getRandomItem(TASK_PRIORITIES),
                    isCompleted: isCompleted,
                    date: specificDate,
                    // İSTATİSTİKLER İÇİN ÇOK ÖNEMLİ:
                    // 'createdAt' ve 'updatedAt' tarihlerini de sahte tarihle
                    // değiştiriyoruz ki 'weeklyActivity' grafiği doğru dolsun.
                    createdAt: specificDate, 
                    updatedAt: isCompleted ? specificDate : new Date() 
                });
                taskPromises.push(task.save());
            }

            // 3. O GÜN İÇİN 1 GÜNLÜK KAYDI OLUŞTUR
            // (Her gün günlük tutulmamış hissi vermek için %80 ihtimalle ekleyelim)
            if (Math.random() > 0.2) { 
                const entry = new JournalEntry({
                    user: user._id,
                    mood: getRandomItem(MOODS),
                    journal: `${getRandomItem(SAMPLE_JOURNALS)} (Gün ${day})`,
                    // İSTATİSTİKLER İÇİN ÇOK ÖNEMLİ:
                    // 'createdAt' tarihini sahte tarihle değiştiriyoruz
                    createdAt: specificDate 
                });
                journalPromises.push(entry.save());
            }
        }
        // --- GÜNCELLEME BİTTİ ---


        // 4. Tüm verilerin kaydedilmesini bekle
        await Promise.all(taskPromises);
        await Promise.all(journalPromises);

        console.log(`✅ ${taskPromises.length} adet sahte GÖREV oluşturuldu.`);
        console.log(`✅ ${journalPromises.length} adet sahte GÜNLÜK kaydı oluşturuldu.`);
        

        console.log('\n--- Tohumlama (Seeding) Başarıyla Tamamlandı! ---');
        console.log('Şimdi `GET /api/stats/summary` rotasını test edebilirsiniz.');

    } catch (err) {
        console.error('Tohumlama sırasında bir hata oluştu:', err.message);
    } finally {
        // Hata olsa da, olmasa da veritabanı bağlantısını kapat
        await mongoose.disconnect();
        console.log('Veritabanı bağlantısı kapatıldı.');
    }
};

// Script'i çalıştır
seedDatabase();