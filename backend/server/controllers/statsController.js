import Task from '../models/Task.js';
import JournalEntry from '../models/JournalEntry.js';
import mongoose from 'mongoose';

// @route   GET /api/stats/summary
// @desc    Kullanıcının tüm istatistik özetini (tasks + journal) al
// @access  Private (authMiddleware ile korunacak)
export const getStatsSummary = async (req, res) => {
    try {
        // 1. Giriş yapmış kullanıcının ID'sini al
        const userId = new mongoose.Types.ObjectId(req.user.id);

        // 2. HAFTALIK AKTİVİTE İÇİN TARİH HESAPLAMASI
        // Bu haftanın Pazar gününü bul (MongoDB'de hafta Pazar günü başlar - 1)
        const today = new Date();
        const firstDayOfWeek = new Date(today.setDate(today.getDate() - today.getDay() + (today.getDay() === 0 ? -6 : 1) - 1)); // Bu Pazar
        firstDayOfWeek.setHours(0, 0, 0, 0);

        // --- PARALEL SORGULAMA BAŞLANGICI ---
        // İki farklı koleksiyonu AYNI ANDA sorgulamak için Promise.all kullanıyoruz.
        // Bu, API'yi çok daha hızlı yapar.

        const [taskStats, journalStats] = await Promise.all([

            // --- SORGULAMA 1: GÖREV (TASK) İSTATİSTİKLERİ ---
            Task.aggregate([
                {
                    // A. Sadece bu kullanıcıya ait görevleri al
                    $match: { user: userId }
                },
                {
                    // B. $facet kullanarak 3 farklı hesaplamayı aynı anda yap
                    $facet: {
                        // B1. Görev Özeti (taskSummary)
                        "taskSummary": [
                            {
                                $group: {
                                    _id: null,
                                    totalTasks: { $sum: 1 },
                                    // isCompleted true ise 1, değilse 0 ekle
                                    completedTasks: {
                                        $sum: { $cond: ["$isCompleted", 1, 0] }
                                    }
                                }
                            }
                        ],
                        // B2. Öncelik Dağılımı (priorityBreakdown)
                        "priorityBreakdown": [
                            {
                                $group: {
                                    _id: "$priority", // 'priority' alanına göre grupla
                                    count: { $sum: 1 } // Her gruptaki sayıyı topla
                                }
                            }
                        ],
                        // B3. Haftalık Aktivite (weeklyActivity)
                        "weeklyActivity": [
                            {
                                // Sadece bu hafta tamamlanan görevleri filtrele
                                $match: {
                                    isCompleted: true,
                                    updatedAt: { $gte: firstDayOfWeek }
                                }
                            },
                            {
                                $group: {
                                    // Tamamlanma tarihine göre haftanın gününe göre grupla
                                    // (1: Pazar, 2: Pzt, 3: Sal, ..., 7: Cmt)
                                    _id: { $dayOfWeek: "$updatedAt" },
                                    completed: { $sum: 1 }
                                }
                            }
                        ]
                    }
                }
            ]),

            // --- SORGULAMA 2: GÜNLÜK (JOURNAL) İSTATİSTİKLERİ ---
            JournalEntry.aggregate([
                {
                    // A. Sadece bu kullanıcıya ait kayıtları al
                    $match: { user: userId }
                },
                {
                    // B. Ruh hali dağılımı (moodHistory)
                    $group: {
                        _id: "$mood", // 'mood' alanına göre grupla
                        count: { $sum: 1 }
                    }
                }
            ])
        ]);

        // --- VERİYİ FORMATLAMA (JSON SÖZLEŞMESİNE UYGUNLUK) ---
        // Backend'in görevi, frontend'in istediği formatı tam olarak sağlamaktır.
        // Sorgu sonucu boş gelse bile, varsayılan (0) değerlere sahip bir
        // yapı (JSON Sözleşmesi) oluşturuyoruz.

        // 1. Varsayılan (default) JSON Sözleşmesi yapısı
        const statsResponse = {
            taskSummary: {
                totalTasks: 0,
                completedTasks: 0,
                completionPercentage: 0,
                pendingTasks: 0
            },
            priorityBreakdown: {
                high: 0,
                medium: 0,
                low: 0
            },
            moodHistory: {
                harika: 0,
                mutlu: 0,
                normal: 0,
                uzgun: 0,
                berbat: 0
            },
            weeklyActivity: [
                { day: "Pzt", completed: 0 },
                { day: "Sal", completed: 0 },
                { day: "Çar", completed: 0 },
                { day: "Per", completed: 0 },
                { day: "Cum", completed: 0 },
                { day: "Cmt", completed: 0 },
                { day: "Paz", completed: 0 }
            ]
        };

        // 2. taskSummary verilerini doldur
        if (taskStats[0].taskSummary.length > 0) {
            const summary = taskStats[0].taskSummary[0];
            statsResponse.taskSummary.totalTasks = summary.totalTasks;
            statsResponse.taskSummary.completedTasks = summary.completedTasks;
            statsResponse.taskSummary.pendingTasks = summary.totalTasks - summary.completedTasks;
            if (summary.totalTasks > 0) {
                statsResponse.taskSummary.completionPercentage = Math.round(
                    (summary.completedTasks / summary.totalTasks) * 100
                );
            }
        }

        // 3. priorityBreakdown verilerini doldur
        // (Not: Modelimizde Türkçe 'Düşük', 'Orta', 'Yüksek' kullandığımızı varsayıyorum)
        taskStats[0].priorityBreakdown.forEach(item => {
            if (item._id === 'Yüksek') statsResponse.priorityBreakdown.high = item.count;
            if (item._id === 'Orta') statsResponse.priorityBreakdown.medium = item.count;
            if (item._id === 'Düşük') statsResponse.priorityBreakdown.low = item.count;
        });

        // 4. moodHistory (Günlük) verilerini doldur
        journalStats.forEach(item => {
            if (statsResponse.moodHistory.hasOwnProperty(item._id)) {
                statsResponse.moodHistory[item._id] = item.count;
            }
        });

        // 5. weeklyActivity verilerini doldur
        // MongoDB Pazar=1, Pzt=2, Sal=3, Çar=4, Per=5, Cum=6, Cmt=7
        const dayMap = {
            2: "Pzt", 3: "Sal", 4: "Çar", 5: "Per", 6: "Cum", 7: "Cmt", 1: "Paz"
        };
        taskStats[0].weeklyActivity.forEach(item => {
            const dayString = dayMap[item._id]; // (örn: 2 -> "Pzt")
            const dayObject = statsResponse.weeklyActivity.find(d => d.day === dayString);
            if (dayObject) {
                dayObject.completed = item.completed;
            }
        });

        // 6. Tamamlanmış JSON'u iOS'a (StatsView) gönder
        res.json(statsResponse);

    } catch (err) {
        console.error('getStatsSummary Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};