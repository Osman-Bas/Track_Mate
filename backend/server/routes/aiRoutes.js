import express from 'express';

// "Bekçi"mizi import ediyoruz
import authMiddleware from '../middleware/authMiddleware.js';

// "AI" (Yapay Zeka) controller fonksiyonumuzu import ediyoruz
import { getAiRecommendations } from '../controllers/aiController.js';

const router = express.Router();

// --- ÖNEMLİ ---
// Bu dosyadaki TÜM rotalar /api/ai ile başlar.
// Ana server.js dosyamızda app.use('/api/ai', aiRoutes) yapacağız.

// @route   GET /api/ai/recommendations
// @desc    Kullanıcının verilerine göre AI önerileri al (AIView)
// @access  Private (KORUMALI)
router.get(
    '/recommendations', // Rotamız (server.js'de /api/ai ile birleşecek)
    authMiddleware,       // 1. Bekçi: Önce giriş yapılmış mı diye kontrol et
    getAiRecommendations  // 2. Bekçi izin verirse, AI fonksiyonunu çalıştır
);

// Rotaları dışa aktar (ESM formatı)
export default router;