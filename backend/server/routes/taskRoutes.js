import express from 'express';
import { check } from 'express-validator'; // Veri doğrulama

// "Bekçi"mizi import ediyoruz
import authMiddleware from '../middleware/authMiddleware.js';

// "Task" (Görev) ile ilgili 5 controller fonksiyonumuzu import ediyoruz
import {
    createTask,
    getMyTasks,
    updateTask,
    deleteTask,
    toggleTaskCompletion
} from '../controllers/taskController.js';

const router = express.Router();

// --- ÖNEMLİ ---
// Bu dosyadaki TÜM rotalar /api/tasks ile başlar
// ve HEPSİ authMiddleware'den geçer.

// @route   POST /api/tasks
// @desc    Yeni bir görev oluştur (AddTaskView)
// @access  Private
router.post(
    '/',
    authMiddleware, // Bekçi: Önce giriş yapılmış mı diye kontrol et
    [
        // Veri doğrulama: Başlık boş olamaz
        check('title', 'Başlık alanı boş bırakılamaz.').not().isEmpty()
    ],
    createTask // Sonra görevi oluştur
);

// @route   GET /api/tasks
// @desc    Giriş yapmış kullanıcının tüm görevlerini al (DashboardView)
// @access  Private
router.get('/', authMiddleware, getMyTasks);

// @route   PUT /api/tasks/:id
// @desc    Belirli bir görevi güncelle (EditTaskView)
// @access  Private
router.put(
    '/:id', // :id -> güncellenecek görevin ID'si (örn: /api/tasks/12345)
    authMiddleware,
    [
        // Güncelleme için de başlığın boş olmadığını kontrol et
        check('title', 'Başlık alanı boş bırakılamaz.').not().isEmpty()
    ],
    updateTask
);

// @route   DELETE /api/tasks/:id
// @desc    Belirli bir görevi sil (DashboardView context menu)
// @access  Private
router.delete('/:id', authMiddleware, deleteTask);

// @route   PATCH /api/tasks/:id/toggle
// @desc    Görevin tamamlanma durumunu (isCompleted) değiştir (DashboardView tap)
// @access  Private
router.patch('/:id/toggle', authMiddleware, toggleTaskCompletion);


// Bu rotaları dışa aktar (ESM formatı)
export default router;