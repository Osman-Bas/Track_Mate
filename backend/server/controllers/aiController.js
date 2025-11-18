import User from '../models/User.js';
import Task from '../models/Task.js';
import JournalEntry from '../models/JournalEntry.js';
import mongoose from 'mongoose';

// Google Generative AI API'si için Gerekli Ayarlar
const API_KEY = process.env.GEMINI_API_KEY; 
const AI_MODEL_NAME = "gemini-2.5-flash-preview-09-2025";
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${AI_MODEL_NAME}:generateContent?key=${API_KEY}`;

// --- JSON CEVAP ŞEMASI (Değişiklik Yok) ---
const RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: {
        "suggestions": {
            type: "ARRAY",
            items: {
                type: "OBJECT",
                properties: {
                    "id": { "type": "STRING" },
                    "title": { "type": "STRING" },
                    "recommendation": { "type": "STRING" },
                    "type": {
                        "type": "STRING",
                        "enum": ["productivity", "activity", "wellness", "media"]
                    }
                },
                required: ["id", "title", "recommendation", "type"]
            }
        }
    },
    required: ["suggestions"]
};


// --- API Fonksiyonu: Kişiselleştirilmiş Önerileri Al ---
// @route   GET /api/ai/recommendations
export const getAiRecommendations = async (req, res) => {
    try {
        // --- 1. VERİ TOPLAMA AŞAMASI ---
        const userId = new mongoose.Types.ObjectId(req.user.id);
        const twoDaysAgo = new Date();
        twoDaysAgo.setHours(0, 0, 0, 0); 
        twoDaysAgo.setDate(twoDaysAgo.getDate() - 1); 

        const [
            currentUser,
            pendingTasks, // Bekleyen Görevler
            recentJournalEntries
        ] = await Promise.all([
            User.findById(userId).select('username currentMood'),
            
            // GÜNCELLEME 1: Artık 'description' alanını da seçiyoruz!
            Task.find({
                user: userId,
                isCompleted: false,
                createdAt: { $gte: twoDaysAgo } 
            })
            .select('title description priority') // <-- 'description' eklendi
            .limit(10),

            JournalEntry.find({
                user: userId,
                createdAt: { $gte: twoDaysAgo } 
            })
            .sort({ createdAt: -1 })
            .limit(3)
            .select('mood journal')
        ]);

        if (!currentUser) {
            return res.status(404).json({ msg: 'Kullanıcı bulunamadı.' });
        }

        // --- 2. AI İÇİN "İÇERİK" (Context) OLUŞTURMA ---
        const userDataSnapshot = {
            kullanici_adi: currentUser.username,
            anlik_ruh_hali: currentUser.currentMood,
            
            // GÜNCELLEME 2: AI'a hem Başlığı hem de Açıklamayı veriyoruz
            bekleyen_gunluk_gorevler: pendingTasks.map(task => ({
                baslik: task.title,
                aciklama: task.description || "Açıklama yok", // Açıklama boşsa belirt
                oncelik: task.priority
            })),
            
            son_gunluk_kayitlari: recentJournalEntries.map(entry => ({
                mood: entry.mood,
                journal: entry.journal
            }))
        };

        // --- 3. AI (GEMINI) İÇİN SİSTEM PROMPT'U ---
        const systemPrompt = `
            Sen 'Track_Mate' adlı bir kişisel gelişim ve üretkenlik asistanısın.
            Görevin, kullanıcının JSON verilerini analiz etmek ve 2-3 adet
            kişiselleştirilmiş, eyleme geçirilebilir öneride bulunmaktır.

            Önerilerin: 'productivity', 'activity', 'wellness', 'media' kategorilerinden
            biri olmalıdır.

            AI MANTIĞI VE SENARYOLAR (GÜNCELLENDİ):
            
            1. ARTIK GÖREV DETAYLARINI BİLİYORSUN:
               - 'bekleyen_gunluk_gorevler' listesindeki 'aciklama' (description)
                 kısmına ÇOK dikkat et.
               - Örnek: Eğer görev başlığı "Toplantı" ise ama açıklamada "Patronla
                 zam görüşmesi" yazıyorsa, bu görevin STRES kaynağı olduğunu anla.
               - Örnek: Eğer görev açıklamasında "Market alışverişi" yazıyorsa, bu
                 basit bir 'activity' (aktivite) olarak değerlendirilebilir.

            2. HİPER-KİŞİSEL BİRLEŞTİRME:
               - EĞER (anlik_ruh_hali 'uzgun' veya 'berbat' ise)
                 VE (Görev Açıklamalarında "proje teslimi", "sınav", "doktor" gibi
                 stresli kelimeler varsa)
               - ÖNERİ: Bu spesifik stresi hedef al.
               - TAVSİYE ÖRNEĞİ: "Fark ettim ki, 'Matematik Sınavı' (açıklamada: 'final konusu çok zor')
                 seni epey germiş. Belki çalışma masandan 15 dakika uzaklaşıp
                 kafanı boşaltmak, formülleri daha iyi hatırlamanı sağlar?"

            3. JENERİK OLMAKTAN KAÇIN.
               - Kullanıcının görev açıklamalarındaki ('aciklama') ve günlüklerindeki
                 özel kelimeleri cevabında geçirerek onu gerçekten dinlediğini kanıtla.

            GENEL KURALLAR:
            - Kullanıcıya 'sen' diliyle, arkadaşça hitap et.
            - ÇOK ÖNEMLİ: Cevabın SADECE "JSON Sözleşmesi" formatında olmalıdır.
        `;

        // --- 4. AI API ÇAĞRISI (FETCH) ---
        const payload = {
            systemInstruction: {
                parts: [{ text: systemPrompt }]
            },
            contents: [{
                parts: [{
                    text: `Kullanıcı Veri Özeti: ${JSON.stringify(userDataSnapshot)}`
                }]
            }],
            generationConfig: {
                responseMimeType: "application/json",
                responseSchema: RESPONSE_SCHEMA
            }
        };

        const response = await fetchWithBackoff(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            throw new Error(`AI API Hatası: ${response.statusText} (Status: ${response.status})`);
        }

        const data = await response.json();
        
        // --- 5. AI CEVABINI İŞLEME VE GÖNDERME ---
        const aiResponseText = data.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!aiResponseText) {
            throw new Error("AI'dan geçerli bir cevap (text) alınamadı.");
        }

        const suggestionsJson = JSON.parse(aiResponseText);

        res.json(suggestionsJson);

    } catch (err) {
        console.error('getAiRecommendations Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};


// --- HATA YÖNETİMİ ---
async function fetchWithBackoff(url, options, retries = 3, delay = 1000) {
    try {
        const response = await fetch(url, options);
        if (response.status === 429 && retries > 0) {
            console.warn(`AI API Kısıtlaması (429). ${delay}ms bekleniyor...`);
            await new Promise(resolve => setTimeout(resolve, delay));
            return fetchWithBackoff(url, options, retries - 1, delay * 2);
        }
        return response;
    } catch (err) {
        if (retries > 0) {
            console.warn(`AI API Hatası. ${delay}ms bekleniyor...`);
            await new Promise(resolve => setTimeout(resolve, delay));
            return fetchWithBackoff(url, options, retries - 1, delay * 2);
        }
        throw err;
    }
}