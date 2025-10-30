import express from 'express';
import 'dotenv/config'; 
import cors from 'cors'; 
import connectDB from './configs/db.js'; 


import authRoutes from './routes/authRoutes.js';


const app = express();

await connectDB();

app.use(cors());

app.use(express.json());

app.get('/', (req, res) => res.send('API is working...'));
app.use('/api/auth', authRoutes);


const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    
    console.log(`Server is running on port ${PORT}`);
});


export default app;
