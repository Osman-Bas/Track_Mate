import express from 'express';
import { check } from 'express-validator'; // Veri doğrulama

// --- GÜNCELLEME (Adım 1) ---
// Controller'dan 'getMe' fonksiyonunu ve middleware'den 'bekçi'yi import et
import { registerUser, loginUser, getMe } from '../controllers/authController.js';
import authMiddleware from '../middleware/authMiddleware.js'; // "Bekçi"mizi import ediyoruz

const router = express.Router();

// @route   POST /api/auth/register
// @desc    Yeni kullanıcı kaydı (Halka açık)
// @access  Public
router.post(
    '/register',
    [
        // Doğrulama kuralları...
        check('fullName', 'İsim alanı boş bırakılamaz.').not().isEmpty(),
        check('username', 'Kullanıcı adı boş bırakılamaz.').not().isEmpty(),
        check('email', 'Lütfen geçerli bir e-posta adresi girin.').isEmail(),
        check('password', 'Şifreniz en az 6 karakter olmalıdır.').isLength({ min: 6 })
    ],
    registerUser
);

// @route   POST /api/auth/login
// @desc    Kullanıcı girişi (Halka açık)
// @access  Public
router.post(
    '/login',
    [
        // Doğrulama kuralları...
        check('email', 'Lütfen geçerli bir e-posta adresi girin.').isEmail(),
        check('password', 'Şifre alanı boş bırakılamaz.').not().isEmpty()
    ],
    loginUser
);

// --- YENİ EKLENEN ROTA (Adım 2) ---
// @route   GET /api/auth/me
// @desc    Giriş yapan kullanıcının bilgilerini al (Korumalı)
// @access  Private
router.get(
    '/me',
    authMiddleware, // 1. "Bekçi"yi bu rotanın önüne koyuyoruz.
    getMe             // 2. Bekçi izin verirse, 'getMe' fonksiyonu çalışır.
);

// ESM formatında dışa aktar
export default router;