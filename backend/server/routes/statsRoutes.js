import express from 'express';

// "Bekçi"mizi import ediyoruz
import authMiddleware from '../middleware/authMiddleware.js';

// "Stats" (İstatistik) controller fonksiyonumuzu import ediyoruz
import { getStatsSummary } from '../controllers/statsController.js';

const router = express.Router();

// --- ÖNEMLİ ---
// Bu dosyadaki TÜM rotalar /api/stats ile başlar.
// Ana server.js dosyamızda app.use('/api/stats', statsRoutes) yapacağız.

// @route   GET /api/stats/summary
// @desc    Kullanıcının tüm istatistik özetini al (StatsView)
// @access  Private
router.get(
    '/summary',         // Rotamız /summary (server.js'de /api/stats ile birleşecek)
    authMiddleware,     // 1. Bekçi: Önce giriş yapılmış mı diye kontrol et
    getStatsSummary     // 2. Bekçi izin verirse, istatistik fonksiyonunu çalıştır
);

// Rotaları dışa aktar (ESM formatı)
export default router;