const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// Kullanıcı şemasını (veritabanı yapısını) tanımlıyoruz
const UserSchema = new Schema({
    // Uygulama içinde kullanılacak @kullaniciadi
    username: {
        type: String,
        required: [true, 'Lütfen bir kullanıcı adı girin.'],
        unique: true, // Kullanıcı adları benzersiz olmalı
        trim: true    // Başındaki/sonundaki boşlukları temizle
    },
    // Giriş için kullanılacak e-posta
    email: {
        type: String,
        required: [true, 'Lütfen e-posta adresinizi girin.'],
        unique: true, // E-posta adresleri benzersiz olmalı
        trim: true,
        lowercase: true, // E-postayı küçük harfe çevirerek kaydet
        match: [
            /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
            'Lütfen geçerli bir e-posta adresi girin.'
        ]
    },
    // Şifre (Her zaman HASH'lenmiş olarak saklanacak)
    password: {
        type: String,
        required: [true, 'Lütfen bir şifre girin.'],
        minlength: [6, 'Şifre en az 6 karakter olmalıdır.'] // Min 6 karakter zorunluluğu
    },
    // Profil fotoğrafı URL'si (ileride kullanmak için)
    profilePictureUrl: {
        type: String,
        default: '' // Başlangıçta boş
    },
    // Kayıt tarihi
    registerDate: {
        type: Date,
        default: Date.now // Kayıt anındaki tarihi otomatik ata
    }
});

// Şemayı bir model olarak dışa aktarıyoruz
// 'User' adı, veritabanında 'users' adında bir koleksiyon oluşturacak
module.exports = mongoose.model('User', UserSchema);
