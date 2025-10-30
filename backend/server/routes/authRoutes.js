const express = require('express');
const router = express.Router();
// Az önce kurduğumuz paketten 'check' fonksiyonunu import ediyoruz
const { check } = require('express-validator');

// Controller fonksiyonlarımızı import ediyoruz
const { registerUser, loginUser } = require('../controllers/authController');

// @route   POST /api/auth/register
// @desc    Yeni kullanıcı kaydı (Sign Up)
// @access  Public
router.post(
    '/register',
    [
        // Gelen veriyi (req.body) kontrol et
        check('fullName', 'İsim alanı boş bırakılamaz.')
            .not()
            .isEmpty(),
        check('username', 'Kullanıcı adı boş bırakılamaz.')
            .not()
            .isEmpty(),
        check('email', 'Lütfen geçerli bir e-posta adresi girin.')
            .isEmail(),
        check('password', 'Şifreniz en az 6 karakter olmalıdır.')
            .isLength({ min: 6 })
    ],
    registerUser // Doğrulama başarılıysa bu fonksiyonu çalıştır
);

// @route   POST /api/auth/login
// @desc    Kullanıcı girişi (Sign In)
// @access  Public
router.post(
    '/login',
    [
        // Giriş için e-posta ve şifreyi kontrol et
        check('email', 'Lütfen geçerli bir e-posta adresi girin.')
            .isEmail(),
        check('password', 'Şifre alanı boş bırakılamaz.')
            .not()
            .isEmpty()
    ],
    loginUser // Doğrulama başarılıysa bu fonksiyonu çalıştır
);

module.exports = router;

