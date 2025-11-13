import mongoose from 'mongoose';
const Schema = mongoose.Schema;

// "Günlük Arşivi" şemasını tanımlıyoruz
const JournalEntrySchema = new Schema({
    // Bu kayıt HANGİ KULLANICIYA ait?
    // User modelimize bir referans (ilişki)
    user: {
        type: Schema.Types.ObjectId,
        ref: 'User', // 'User' modeline bağlı
        required: true
    },
    // Plandaki 'mood' alanı (5'li skala)
    mood: {
        type: String,
        // Plan 1'deki (User modeli) enum ile aynı olmalı
        enum: ['berbat', 'uzgun', 'normal', 'mutlu', 'harika'],
        required: true
    },
    // Plandaki 'journal' (günlük) metni
    journal: {
        type: String,
        default: '' // Opsiyonel, boş olabilir
    }
}, {
    // 'createdAt' (oluşturulma tarihi) ve 'updatedAt'
    // alanlarını otomatik ekler.
    // İstatistikler için 'createdAt'ı kullanacağız.
    timestamps: true
});

// Modeli ESM formatında dışa aktar
// 'JournalEntry' adı, veritabanında 'journalentries' koleksiyonunu oluşturacak
export default mongoose.model('JournalEntry', JournalEntrySchema);