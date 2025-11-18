import Task from '../models/Task.js';
import JournalEntry from '../models/JournalEntry.js';
import mongoose from 'mongoose';

// @route   GET /api/stats/summary
// @desc    Kullanıcının istatistik özetini (Filtreli: Haftalık/Aylık) al
// @access  Private
export const getStatsSummary = async (req, res) => {
    try {
        const userId = new mongoose.Types.ObjectId(req.user.id);

        // --- TARİH HESAPLAMALARI ---
        const today = new Date();
        
        // 1. BU HAFTANIN BAŞLANGICI (Pazar gecesi 00:00)
        // (Görev Öncelik Dağılımı ve Haftalık Aktivite için)
        const firstDayOfWeek = new Date(today);
        firstDayOfWeek.setDate(today.getDate() - today.getDay()); // Pazar gününe git
        firstDayOfWeek.setHours(0, 0, 0, 0);

        // 2. 30 GÜN ÖNCESİ
        // (Ruh Hali Dağılımı için)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        thirtyDaysAgo.setHours(0, 0, 0, 0);


        // --- PARALEL SORGULAMA ---
        const [taskStats, journalStats] = await Promise.all([

            // --- SORGULAMA 1: GÖREV (TASK) İSTATİSTİKLERİ ---
            Task.aggregate([
                {
                    // Kullanıcıyı filtrele
                    $match: { user: userId }
                },
                {
                    $facet: {
                        // A. Genel Özet (taskSummary) - GENEL KALABİLİR veya HAFTALIK YAPILABİLİR
                        // Genelde "Bekleyen İşler" toplam iş yükünü gösterdiği için tarih filtresi koymuyoruz.
                        "taskSummary": [
                            {
                                $group: {
                                    _id: null,
                                    totalTasks: { $sum: 1 },
                                    completedTasks: { $sum: { $cond: ["$isCompleted", 1, 0] } }
                                }
                            }
                        ],
                        
                        // B. Öncelik Dağılımı (priorityBreakdown) - ARTIK SADECE BU HAFTA
                        "priorityBreakdown": [
                            {
                                // GÜNCELLEME: Sadece bu hafta oluşturulan görevleri al
                                $match: { 
                                    createdAt: { $gte: firstDayOfWeek } 
                                }
                            },
                            {
                                $group: {
                                    _id: "$priority",
                                    count: { $sum: 1 }
                                }
                            }
                        ],

                        // C. Haftalık Aktivite (weeklyActivity) - SADECE BU HAFTA TAMAMLANANLAR
                        "weeklyActivity": [
                            {
                                // GÜNCELLEME: Sadece bu hafta TAMAMLANANLAR (updatedAt)
                                $match: {
                                    isCompleted: true,
                                    updatedAt: { $gte: firstDayOfWeek }
                                }
                            },
                            {
                                $group: {
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
                    // GÜNCELLEME: Sadece SON 30 GÜNÜN kayıtlarını al
                    $match: { 
                        user: userId,
                        createdAt: { $gte: thirtyDaysAgo } 
                    }
                },
                {
                    $group: {
                        _id: "$mood",
                        count: { $sum: 1 }
                    }
                }
            ])
        ]);

        // --- VERİYİ FORMATLAMA (JSON Sözleşmesi) ---
        // Burası değişmedi, aynı formatı koruyoruz.

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

        // 1. Task Summary Doldur
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

        // 2. Priority Breakdown Doldur (Bu Hafta)
        taskStats[0].priorityBreakdown.forEach(item => {
            if (item._id === 'Yüksek') statsResponse.priorityBreakdown.high = item.count;
            if (item._id === 'Orta') statsResponse.priorityBreakdown.medium = item.count;
            if (item._id === 'Düşük') statsResponse.priorityBreakdown.low = item.count;
        });

        // 3. Mood History Doldur (Son 30 Gün)
        journalStats.forEach(item => {
            if (statsResponse.moodHistory.hasOwnProperty(item._id)) {
                statsResponse.moodHistory[item._id] = item.count;
            }
        });

        // 4. Weekly Activity Doldur (Bu Hafta)
        const dayMap = { 2: "Pzt", 3: "Sal", 4: "Çar", 5: "Per", 6: "Cum", 7: "Cmt", 1: "Paz" };
        taskStats[0].weeklyActivity.forEach(item => {
            const dayString = dayMap[item._id];
            const dayObject = statsResponse.weeklyActivity.find(d => d.day === dayString);
            if (dayObject) {
                dayObject.completed = item.completed;
            }
        });

        res.json(statsResponse);

    } catch (err) {
        console.error('getStatsSummary Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};