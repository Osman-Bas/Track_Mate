import jwt from 'jsonwebtoken';

// Bu bir "middleware" fonksiyonudur.
// "req" (istek) ve "res" (cevap) arasında duran bir "bekçidir".
// "next", bu bekçinin "Tamam, bir sonraki adıma geçebilirsin" demesidir.
const authMiddleware = (req, res, next) => {
    // 1. iOS uygulamasının isteğinin "Header" (Başlık) bölümünden
    //    'Authorization' bilgisini oku.
    const authHeader = req.headers.authorization;

    // 2. Bu başlık yok mu VEYA "Bearer " (boşluk önemli) ile başlamıyor mu?
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        // Eğer yoksa, bu isteği yapan kişi giriş yapmamış demektir.
        // İsteği hemen reddet.
        return res.status(401).json({ msg: 'Yetkilendirme reddedildi: Token bulunamadı.' });
    }

    try {
        // 3. "Bearer <token>" yazısındaki token'ı ayır ve al.
        const token = authHeader.split(' ')[1];

        // 4. Token'ı, .env dosyamızdaki gizli anahtarla (JWT_SECRET) doğrula.
        //    Bu, "Bu bileti gerçekten ben mi imzaladım?" kontrolüdür.
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 5. Token geçerliyse, içindeki kullanıcı bilgisini (payload) al
        //    ve isteğin (req) içine ekle.
        //    (Token'ı oluştururken payload içine { user: { id: ... } } koymuştuk)
        req.user = decoded.user;

        // 6. Bekçi görevini tamamladı: "Her şey yolunda, devam et."
        next();

    } catch (err) {
        // Token'ın süresi dolmuşsa veya geçersizse, 'jwt.verify' hata verecektir.
        res.status(401).json({ msg: 'Token geçersiz veya süresi dolmuş.' });
    }
};

// Bu fonksiyonu dışa aktar (ESM formatı)
export default authMiddleware;