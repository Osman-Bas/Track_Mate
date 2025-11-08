import express from 'express';
import 'dotenv/config'; // .env dosyasını yükler
import cors from 'cors';
import connectDB from './configs/db.js';

// --- ROTA DOSYALARINI IMPORT ET ---
import authRoutes from './routes/authRoutes.js';
// YENİ EKLENEN SATIR (Adım 4.1)
import taskRoutes from './routes/taskRoutes.js'; // Task rotalarını import et

// Veritabanına bağlan
connectDB();

const app = express();

// Middleware (ara yazılımlar)
app.use(cors()); // Herkese açık API için
app.use(express.json()); // JSON body'lerini okuyabilmek için

// --- ROTALARI KULLAN ---

// Ana (Test) Rota
app.get('/', (req, res) => res.send("API is working..."));

// 1. Auth Rotaları

app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);


// Port'u .env'den al, bulamazsan 3000'i kullan
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

export default app;