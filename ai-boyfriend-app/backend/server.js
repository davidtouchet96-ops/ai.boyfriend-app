import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';
import rateLimit from 'express-rate-limit';
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const httpServer = createServer(app);

const allowedOrigins = [
  process.env.FRONTEND_URL || 'http://localhost:5173',
  'http://localhost:3000'
];

app.use(cors({
  origin: allowedOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use(limiter);

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB Error: ${error.message}`);
    setTimeout(connectDB, 5000);
  }
};
connectDB();

const io = new Server(httpServer, { cors: { origin: allowedOrigins, credentials: true }});
io.on('connection', (socket) => {
  socket.on('join-room', (userId) => socket.join(userId));
  socket.on('send-message', (data) => io.to(data.userId).emit('new-message', data));
});

// Import routes
import authRoutes from './routes/auth.js';
import chatRoutes from './routes/chat.js';
import characterRoutes from './routes/character.js';
import imageRoutes from './routes/images.js';
import groupChatRoutes from './routes/groupChat.js';

app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/character', characterRoutes);
app.use('/api/images', imageRoutes);
app.use('/api/group', groupChatRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', mongo: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected' });
});

if (process.env.NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, '../frontend/dist')));
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/dist/index.html'));
  });
}

const PORT = process.env.PORT || 3001;
httpServer.listen(PORT, () => console.log(`✅ Server running on port ${PORT}`));
