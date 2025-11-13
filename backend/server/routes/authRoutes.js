import express from 'express';
import { check } from 'express-validator';
import authMiddleware from '../middleware/authMiddleware.js';

import {
    registerUser,
    loginUser,
    getMe,
    updateMood 
} from '../controllers/authController.js';

const router = express.Router();

// @route   POST /api/auth/register (Public)
router.post(
    '/register',
    [
        check('fullName', 'İsim alanı boş bırakılamaz.').not().isEmpty(),
        check('username', 'Kullanıcı adı boş bırakılamaz.').not().isEmpty(),
        check('email', 'Lütfen geçerli bir e-posta adresi girin.').isEmail(),
        check('password', 'Şifreniz en az 6 karakter olmalıdır.').isLength({ min: 6 })
    ],
    registerUser
);

// @route   POST /api/auth/login (Public)
router.post(
    '/login',
    [
        check('email', 'Lütfen geçerli bir e-posta adresi girin.').isEmail(),
        check('password', 'Şifre alanı boş bırakılamaz.').not().isEmpty()
    ],
    loginUser
);

// @route   GET /api/auth/me (Private)
router.get('/me', authMiddleware, getMe);


router.patch(
    '/mood',
    authMiddleware, // 1. Bekçi: Giriş yapılmış olmalı
    [
        // 2. Doğrulama: Gelen 'mood' değeri modeldeki enum listesinde olmalı
        check('mood', 'Geçerli bir ruh hali değeri girilmedi.')
            .isIn(['berbat', 'uzgun', 'normal', 'mutlu', 'harika'])
    ],
    updateMood // 3. Fonksiyonu çalıştır
);

export default router;