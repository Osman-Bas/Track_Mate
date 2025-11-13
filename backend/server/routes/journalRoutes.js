import express from 'express';
import { check } from 'express-validator'; // Veri doğrulama

// "Bekçi"mizi import ediyoruz
import authMiddleware from '../middleware/authMiddleware.js';

// Controller'dan 2 yeni fonksiyonumuzu import ediyoruz
import {
    createJournalEntry,
    getMyJournalEntries
} from '../controllers/journalController.js';

const router = express.Router();

// --- ÖNEMLİ ---
// Bu dosyadaki TÜM rotalar /api/journal ile başlar
// ve HEPSİ authMiddleware'den geçer.

// @route   POST /api/journal
// @desc    Yeni bir günlük kaydı oluştur (Plan 2.2.A)
// @access  Private
router.post(
    '/',
    authMiddleware, // 1. Bekçi: Giriş yapılmış olmalı
    [
        // 2. Doğrulama: Planda istendiği gibi 'mood' alanı zorunlu
        //    ve 5'li skalada olmalı.
        check('mood', 'Geçerli bir ruh hali değeri girilmedi.')
            .isIn(['berbat', 'uzgun', 'normal', 'mutlu', 'harika'])
    ],
    createJournalEntry // 3. Fonksiyonu çalıştır
);

// @route   GET /api/journal
// @desc    Giriş yapmış kullanıcının tüm günlük kayıtlarını al (Plan 2.2.B)
// @access  Private
router.get(
    '/',
    authMiddleware, // 1. Bekçi: Giriş yapılmış olmalı
    getMyJournalEntries // 2. Fonksiyonu çalıştır
);


export default router;