import Task from '../models/Task.js'; // 1. Adımda oluşturduğumuz Task modelini import et
import { validationResult } from 'express-validator'; // Rotalarda kullanacağımız doğrulama için

// --- 1. YENİ GÖREV OLUŞTUR ---
// @route   POST /api/tasks
// @desc    Yeni bir görev oluştur
// @access  Private (authMiddleware ile korunacak)
export const createTask = async (req, res) => {
    // Rota'da (Adım 3'te) ekleyeceğimiz doğrulama kurallarının sonucunu kontrol et
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        // 1. iOS'tan (AddTaskView) gelen verileri al:
        const { title, description, date, priority } = req.body;

        // 2. Yeni bir Task nesnesi oluştur.
        //    EN ÖNEMLİ KISIM: 'user' alanını, authMiddleware'den gelen
        //    'req.user.id' (giriş yapmış kullanıcının ID'si) ile doldur.
        const newTask = new Task({
            user: req.user.id, // Bu görevin sahibini belirle
            title,
            description,
            date,
            priority
        });

        // 3. Görevi veritabanına kaydet
        const task = await newTask.save();

        // 4. Yeni oluşturulan görevi iOS'a geri gönder (ID'si ile birlikte)
        res.status(201).json(task); // 201 = Created

    } catch (err) {
        console.error('createTask Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};

// --- 2. GİRİŞ YAPAN KULLANICININ TÜM GÖREVLERİNİ AL ---
// @route   GET /api/tasks
// @desc    Giriş yapmış kullanıcının tüm görevlerini al
// @access  Private
export const getMyTasks = async (req, res) => {
    try {
        // Veritabanında 'user' alanı, giriş yapmış kullanıcının ID'si
        // ('req.user.id') ile eşleşen TÜM görevleri bul.
        // En yeniden en eskiye doğru sırala.
        const tasks = await Task.find({ user: req.user.id }).sort({ createdAt: -1 });

        // Görev dizisini (array) iOS'a gönder
        res.json(tasks);

    } catch (err) {
        console.error('getMyTasks Hatası:', err.message);
        res.status(500).send('Sunucu Hatası');
    }
};

// --- 3. BİR GÖREVİ GÜNCELLE (EDIT TASK) ---
// @route   PUT /api/tasks/:id
// @desc    Bir görevi güncelle (EditTaskView)
// @access  Private
export const updateTask = async (req, res) => {
    // Rota'daki 'check' kontrollerinden gelen hataları yakala
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ msg: errors.array()[0].msg });
    }

    try {
        // 1. Güncellenecek veriyi iOS'tan (EditTaskView) al
        const { title, description, date, priority } = req.body;
        const taskId = req.params.id; // URL'den gelen görev ID'si (örn: .../api/tasks/12345)

        // 2. Güvenlik Kontrolü 1: Görev veritabanında var mı?
        let task = await Task.findById(taskId);
        if (!task) {
            return res.status(404).json({ msg: 'Görev bulunamadı.' }); // 404 = Not Found
        }

        // 3. GÜVENLİK KONTROLÜ 2 (ÇOK ÖNEMLİ):
        //    Bu görev, giriş yapmış kullanıcıya mı ait?
        //    (Başka bir kullanıcının görevini düzenlemesini engelle)
        if (task.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Yetkiniz yok.' }); // 401 = Unauthorized
        }

        // 4. Her şey yolundaysa, görevi güncelle
        const updatedFields = { title, description, date, priority };
        
        task = await Task.findByIdAndUpdate(
            taskId,
            { $set: updatedFields }, // Alanları yeni verilerle güncelle
            { new: true } // Güncellenmiş (yeni) halini geri döndür
        );

        // 5. Güncellenmiş görevi iOS'a gönder
        res.json(task);

    } catch (err) {
        console.error('updateTask Hatası:', err.message);
        // MongoDB ID formatı yanlışsa (örn: .../api/tasks/123)
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Görev bulunamadı.' });
        }
        res.status(500).send('Sunucu Hatası');
    }
};

// --- 4. BİR GÖREVİ SİL ---
// @route   DELETE /api/tasks/:id
// @desc    Bir görevi sil (DashboardView context menu)
// @access  Private
export const deleteTask = async (req, res) => {
    try {
        const taskId = req.params.id; // URL'den gelen görev ID'si

        // 2. Güvenlik Kontrolü 1: Görev var mı?
        let task = await Task.findById(taskId);
        if (!task) {
            return res.status(404).json({ msg: 'Görev bulunamadı.' });
        }

        // 3. GÜVENLİK KONTROLÜ 2: Görev bu kullanıcıya mı ait?
        if (task.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Yetkiniz yok.' });
        }

        // 4. Her şey yolundaysa, görevi veritabanından sil
        await Task.findByIdAndDelete(taskId);

        // 5. Başarı mesajı gönder
        res.json({ msg: 'Görev başarıyla silindi.' });

    } catch (err) {
        console.error('deleteTask Hatası:', err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Görev bulunamadı.' });
        }
        res.status(500).send('Sunucu Hatası');
    }
};

// --- 5. GÖREV TAMAMLANMA DURUMUNU DEĞİŞTİR (TOGGLE) ---
// @route   PATCH /api/tasks/:id/toggle
// @desc    Görevin 'isCompleted' durumunu değiştir (DashboardView tap)
// @access  Private
export const toggleTaskCompletion = async (req, res) => {
    try {
        const taskId = req.params.id; // URL'den gelen görev ID'si

        // 2. Güvenlik Kontrolü 1: Görev var mı?
        let task = await Task.findById(taskId);
        if (!task) {
            return res.status(404).json({ msg: 'Görev bulunamadı.' });
        }

        // 3. GÜVENLİK KONTROLÜ 2: Görev bu kullanıcıya mı ait?
        if (task.user.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Yetkiniz yok.' });
        }

        // 4. Durumu tersine çevir (true ise false, false ise true yap)
        task.isCompleted = !task.isCompleted;

        // 5. Değişikliği kaydet
        await task.save();

        // 6. Güncellenmiş görevi iOS'a gönder
        res.json(task);

    } catch (err) {
        console.error('toggleTask Hatası:', err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Görev bulunamadı.' });
        }
        res.status(500).send('Sunucu Hatası');
    }
};