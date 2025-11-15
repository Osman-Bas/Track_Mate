import User from '../models/User.js';
import Task from '../models/Task.js';
import JournalEntry from '../models/JournalEntry.js';
import mongoose from 'mongoose';

// Google Generative AI API'si için Gerekli Ayarlar
const API_KEY = process.env.GEMINI_API_KEY; // .env dosyasından okuyoruz
const AI_MODEL_NAME = "gemini-2.5-flash-preview-09-2025";
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${AI_MODEL_NAME}:generateContent?key=${API_KEY}`;

// --- JSON CEVAP ŞEMASI (YAZIM HATASI DÜZELTİLDİ) ---
const RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: {
        "suggestions": {
            type: "ARRAY",
            items: {
                type: "OBJECT",
                properties: {
                    // --- HATA BURADAYDI (DÜZELTİLDİ) ---
                    "id": { "type": "STRING" }, // "type: " -> "type": "
                    "title": { "type": "STRING" }, // "type: " -> "type": "
                    // --- DÜZELTME BİTTİ ---
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
        twoDaysAgo.setHours(0, 0, 0, 0); // Bu sabah 00:00
        twoDaysAgo.setDate(twoDaysAgo.getDate() - 1); // Dün sabah 00:00

        const [
            currentUser,
            pendingTasks,
            recentJournalEntries
        ] = await Promise.all([
            User.findById(userId).select('username currentMood'),
            Task.find({
                user: userId,
                isCompleted: false,
                createdAt: { $gte: twoDaysAgo }
            })
            .select('title priority')
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
            bekleyen_gunluk_gorevler: pendingTasks.map(task => ({
                title: task.title,
                priority: task.priority
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
            kişiselleştirilmiş, eyleme geçirilebilir ve destekleyici öneride bulunmaktır.

            Önerilerin, JSON şemasında belirtilen kategorilerden ('type') birine
            ait olmalıdır: 'productivity', 'activity', 'wellness', 'media'.

            AI MANTIĞI VE SENARYOLAR (GÜNCELLENDİ):
            
            1. 'son_gunluk_kayitlari'ndaki 'journal' metinlerine ve
               'bekleyen_gunluk_gorevler' listesindeki 'title' (başlık)
               metinlerine ÇOK DİKKAT ET.
               
               Bu iki listeyi BİRLEŞTİREREK öneri yap.

            2. HİPER-KİŞİSEL SENARYO (Örnek):
               - EĞER (anlik_ruh_hali 'uzgun' ise)
                 VE ('son_gunluk_kayitlari'nda "Patronla tartıştım" gibi İŞ STRESİ varsa)
                 VE ('bekleyen_gunluk_gorevler' listesinde "Acil Sunum" adlı bir görev varsa)
               - ÖNERİ: Bu üç bilgiyi birleştir. Jenerik 'Pomodoro' önerme.
               - TAVSİYE (Productivity): "Fark ettim ki, patronunla tartıştığın
                 bir günde bir de 'Acil Sunum' göreviyle uğraşıyorsun. Bu
                 gerçekten bunaltıcı. Belki 'Acil Sunum' görevini yarına
                 ertelemeyi düşünebilirsin?"
               - TAVSİYE (Media/Wellness): "İş stresi yaşadığın için, bu akşam
                 kafanı tamamen dağıtacak ('İş' ile ilgili olmayan) bir komedi
                 filmi ('The Office' değil, 'Airplane!' gibi) izlemeye ne dersin?"

            3. JENERİK OLMAKTAN KAÇIN.
               - Her zaman 'Ted Lasso', 'yürüyüş yapmak', 'Pomodoro' önerme.
               - Kullanıcının görev başlıklarını ('title') ve günlük metinlerini ('journal')
                 cevabında kullanarak ona *gerçekten* dinlendiğini hissettir.

            GENEL KURALLAR:
            - Kullanıcıya 'sen' diliyle, arkadaşça ve anlayışlı bir tonda hitap et.
            - ÇOK ÖNEMLİ: Cevabın SADECE ve SADECE "JSON Sözleşmesi"nde
              belirtilen JSON formatında olmalıdır. Başka hiçbir metin (merhaba, vb.) ekleme.
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


// --- HATA YÖNETİMİ: Exponential Backoff (API limitlerine takılmamak için) ---
async function fetchWithBackoff(url, options, retries = 3, delay = 1000) {
    try {
        const response = await fetch(url, options);
        if (response.status === 429 && retries > 0) {
            console.warn(`AI API Kısıtlaması (429). ${delay}ms bekleniyor... Kalan deneme: ${retries - 1}`);
            await new Promise(resolve => setTimeout(resolve, delay));
            return fetchWithBackoff(url, options, retries - 1, delay * 2);
        }
        return response;
    } catch (err) {
        if (retries > 0) {
            console.warn(`AI API (Fetch) Hatası. ${delay}ms bekleniyor... Hata: ${err.message}`);
            await new Promise(resolve => setTimeout(resolve, delay));
            return fetchWithBackoff(url, options, retries - 1, delay * 2);
        }
        throw err;
    }
}