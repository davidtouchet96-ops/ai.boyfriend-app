#!/bin/bash

# AI Boyfriend App Auto-Setup Script
echo "Creating AI Boyfriend App..."

# Create directory structure
mkdir -p ai-boyfriend-app/{backend/{middleware,models,routes,services,uploads},frontend/{src/{components,pages,store},public},.github/workflows}
cd ai-boyfriend-app

# Backend package.json
cat > backend/package.json << 'EOF'
{
  "name": "ai-boyfriend-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^7.5.0",
    "socket.io": "^4.7.2",
    "axios": "^1.5.0",
    "multer": "^1.4.5-lts.1",
    "express-rate-limit": "^6.10.0",
    "stripe": "^12.18.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Backend .env.example
cat > backend/.env.example << 'EOF'
PORT=3001
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/ai-boyfriend?retryWrites=true&w=majority
JWT_SECRET=your_super_secret_random_string_here
VENICE_API_KEY=your_venice_api_key_here
ELEVENLABS_API_KEY=your_elevenlabs_key_here
STRIPE_SECRET_KEY=sk_test_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
FRONTEND_URL=http://localhost:5173
NODE_ENV=development
EOF

# Backend server.js
cat > backend/server.js << 'ENDOFFILE'
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
    console.log(\`✅ MongoDB Connected: \${conn.connection.host}\`);
  } catch (error) {
    console.error(\`❌ MongoDB Error: \${error.message}\`);
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
httpServer.listen(PORT, () => console.log(\`✅ Server running on port \${PORT}\`));
ENDOFFILE

# Create auth middleware
cat > backend/middleware/auth.js << 'EOF'
import jwt from 'jsonwebtoken';
import { User } from '../models/User.js';

export const authMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user) return res.status(401).json({ error: 'User not found' });
    req.userId = user._id;
    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
EOF

# Create User model
cat > backend/models/User.js << 'EOF'
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  ageVerified: { type: Boolean, default: false },
  subscription: { tier: { type: String, enum: ['free', 'premium', 'vip'], default: 'free' }, expiresAt: Date },
  preferences: { contentIntensity: { type: Number, min: 1, max: 5, default: 3 } },
  createdAt: { type: Date, default: Date.now }
});

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

export const User = mongoose.model('User', userSchema);
EOF

# Create Character model
cat > backend/models/Character.js << 'EOF'
import mongoose from 'mongoose';

const characterSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  age: { type: Number, min: 18 },
  personality: { type: { type: String, enum: ['dominant', 'submissive', 'romantic', 'playful', 'mysterious', 'protective'] }, description: String },
  appearance: { height: String, build: String, hairColor: String, eyeColor: String, ethnicity: String, style: String },
  backstory: String,
  intimacyLevel: { type: Number, min: 0, max: 100, default: 0 },
  mood: { current: { type: String, default: 'happy' }, arousal: { type: Number, default: 30 }, affection: { type: Number, default: 50 } },
  createdAt: { type: Date, default: Date.now }
});

export const Character = mongoose.model('Character', characterSchema);
EOF

# Create Message model
cat > backend/models/Message.js << 'EOF'
import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  characterId: { type: mongoose.Schema.Types.ObjectId, ref: 'Character' },
  groupChatId: { type: mongoose.Schema.Types.ObjectId, ref: 'GroupChat' },
  role: { type: String, enum: ['user', 'assistant'], required: true },
  content: { type: String, required: true },
  type: { type: String, enum: ['text', 'image', 'voice', 'video'], default: 'text' },
  mediaUrl: String,
  isNSFW: { type: Boolean, default: false },
  timestamp: { type: Date, default: Date.now }
});

export const Message = mongoose.model('Message', messageSchema);
EOF

# Create GroupChat model
cat > backend/models/GroupChat.js << 'EOF'
import mongoose from 'mongoose';

const groupChatSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  description: String,
  characters: [{ characterId: { type: mongoose.Schema.Types.ObjectId, ref: 'Character' } }],
  settings: { groupDynamic: { type: String, default: 'friendly' } },
  createdAt: { type: Date, default: Date.now }
});

export const GroupChat = mongoose.model('GroupChat', groupChatSchema);
EOF

# Create auth routes
cat > backend/routes/auth.js << 'EOF'
import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { User } from '../models/User.js';

const router = express.Router();

router.post('/register', async (req, res) => {
  try {
    const { username, email, password, ageVerified } = req.body;
    if (!ageVerified) return res.status(400).json({ error: 'Age verification required' });
    
    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) return res.status(400).json({ error: 'User already exists' });

    const user = new User({ username, email, password, ageVerified });
    await user.save();

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user._id, username, email, subscription: user.subscription } });
  } catch (error) {
    res.status(500).json({ error: 'Registration failed' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user._id, username: user.username, email, subscription: user.subscription } });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

router.get('/me', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-password');
    res.json(user);
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

export default router;
EOF

# Create character routes
cat > backend/routes/character.js << 'EOF'
import express from 'express';
import { Character } from '../models/Character.js';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

router.post('/create', authMiddleware, async (req, res) => {
  try {
    const character = new Character({ ...req.body, userId: req.userId });
    await character.save();
    res.json(character);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create character' });
  }
});

router.get('/list', authMiddleware, async (req, res) => {
  try {
    const characters = await Character.find({ userId: req.userId });
    res.json(characters);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch characters' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const character = await Character.findOne({ _id: req.params.id, userId: req.userId });
    if (!character) return res.status(404).json({ error: 'Not found' });
    res.json(character);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch character' });
  }
});

export default router;
EOF

# Create chat routes
cat > backend/routes/chat.js << 'EOF'
import express from 'express';
import { Message } from '../models/Message.js';
import { Character } from '../models/Character.js';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

router.post('/send', authMiddleware, async (req, res) => {
  try {
    const { characterId, content } = req.body;
    const character = await Character.findOne({ _id: characterId, userId: req.userId });
    if (!character) return res.status(404).json({ error: 'Character not found' });

    const userMessage = new Message({ userId: req.userId, characterId, role: 'user', content, timestamp: new Date() });
    await userMessage.save();

    const aiMessage = new Message({
      userId: req.userId,
      characterId,
      role: 'assistant',
      content: \`Hey babe! \${character.name} here. You said: "\${content}" - I'm always here for you ❤️\`,
      timestamp: new Date()
    });
    await aiMessage.save();

    res.json({ userMessage, aiMessage });
  } catch (error) {
    res.status(500).json({ error: 'Failed to send message' });
  }
});

router.get('/history/:characterId', authMiddleware, async (req, res) => {
  try {
    const messages = await Message.find({ userId: req.userId, characterId: req.params.characterId }).sort({ timestamp: 1 }).limit(100);
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

export default router;
EOF

# Create image routes
cat > backend/routes/images.js << 'EOF'
import express from 'express';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

router.post('/generate', authMiddleware, async (req, res) => {
  if (req.user.subscription.tier === 'free') {
    return res.status(403).json({ error: 'Image generation requires Premium' });
  }
  res.json({ url: 'https://via.placeholder.com/1024?text=AI+Generated+Image' });
});

export default router;
EOF

# Create group chat routes
cat > backend/routes/groupChat.js << 'EOF'
import express from 'express';
import { GroupChat } from '../models/GroupChat.js';
import { Message } from '../models/Message.js';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { name, description, characterIds } = req.body;
    const groupChat = new GroupChat({ userId: req.userId, name, description, characters: characterIds.map(id => ({ characterId: id })) });
    await groupChat.save();
    const populated = await GroupChat.findById(groupChat._id).populate('characters.characterId');
    res.json(populated);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create group' });
  }
});

router.get('/list', authMiddleware, async (req, res) => {
  try {
    const groups = await GroupChat.find({ userId: req.userId }).populate('characters.characterId', 'name');
    res.json(groups);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch groups' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const group = await GroupChat.findOne({ _id: req.params.id, userId: req.userId }).populate('characters.characterId');
    if (!group) return res.status(404).json({ error: 'Not found' });
    res.json(group);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch group' });
  }
});

router.get('/:id/history', authMiddleware, async (req, res) => {
  try {
    const messages = await Message.find({ userId: req.userId, groupChatId: req.params.id }).populate('characterId', 'name').sort({ timestamp: 1 }).limit(100);
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

router.post('/:id/message', authMiddleware, async (req, res) => {
  try {
    const { content } = req.body;
    const group = await GroupChat.findOne({ _id: req.params.id, userId: req.userId }).populate('characters.characterId');
    if (!group) return res.status(404).json({ error: 'Group not found' });

    const userMessage = new Message({ userId: req.userId, groupChatId: group._id, role: 'user', content, timestamp: new Date() });
    await userMessage.save();

    const respondingChar = group.characters[Math.floor(Math.random() * group.characters.length)].characterId;
    const aiMessage = new Message({
      userId: req.userId,
      groupChatId: group._id,
      characterId: respondingChar._id,
      role: 'assistant',
      content: \`\${respondingChar.name}: Hey everyone! \${content}\`,
      timestamp: new Date()
    });
    await aiMessage.save();

    res.json({ userMessage, aiMessage });
  } catch (error) {
    res.status(500).json({ error: 'Failed to send message' });
  }
});

export default router;
EOF

echo "✅ Backend files created!"

# Frontend files
cat > frontend/package.json << 'EOF'
{
  "name": "ai-boyfriend-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.15.0",
    "axios": "^1.5.0",
    "socket.io-client": "^4.7.2",
    "zustand": "^4.4.1",
    "framer-motion": "^10.16.4",
    "lucide-react": "^0.279.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.3",
    "vite": "^4.4.5",
    "tailwindcss": "^3.3.3",
    "autoprefixer": "^10.4.15",
    "postcss": "^8.4.29"
  }
}
EOF

cat > frontend/vite.config.js << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
});
EOF

cat > frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        pink: { 400: '#f472b6', 500: '#ec4899', 600: '#db2777' },
        purple: { 500: '#a855f7', 600: '#9333ea' }
      }
    },
  },
  plugins: [],
}
EOF

cat > frontend/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AI Boyfriend</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

mkdir -p frontend/src

cat > frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f0f0f; }
::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: rgba(0, 0, 0, 0.3); }
::-webkit-scrollbar-thumb { background: rgba(236, 72, 153, 0.5); border-radius: 4px; }
EOF

cat > frontend/src/main.jsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>
);
EOF

cat > frontend/src/App.jsx << 'EOF'
import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { useAuthStore } from './store/authStore';

import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Chat from './pages/Chat';
import CharacterCreator from './pages/CharacterCreator';
import GroupChat from './pages/GroupChat';
import CreateGroup from './pages/CreateGroup';

function PrivateRoute({ children }) {
  const { isAuthenticated } = useAuthStore();
  return isAuthenticated ? children : <Navigate to="/login" />;
}

function App() {
  const { checkAuth } = useAuthStore();
  useEffect(() => { checkAuth(); }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-pink-900 to-red-900">
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/" element={<PrivateRoute><Dashboard /></PrivateRoute>} />
        <Route path="/chat/:characterId" element={<PrivateRoute><Chat /></PrivateRoute>} />
        <Route path="/create" element={<PrivateRoute><CharacterCreator /></PrivateRoute>} />
        <Route path="/group/:groupId" element={<PrivateRoute><GroupChat /></PrivateRoute>} />
        <Route path="/create-group" element={<PrivateRoute><CreateGroup /></PrivateRoute>} />
      </Routes>
    </div>
  );
}

export default App;
EOF

mkdir -p frontend/src/store

cat > frontend/src/store/authStore.js << 'EOF'
import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useAuthStore = create((set) => ({
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: !!localStorage.getItem('token'),
  
  login: async (email, password) => {
    try {
      const res = await axios.post(\`\${API_URL}/auth/login\`, { email, password });
      localStorage.setItem('token', res.data.token);
      set({ user: res.data.user, token: res.data.token, isAuthenticated: true });
      return true;
    } catch (error) {
      return false;
    }
  },
  
  register: async (username, email, password, ageVerified) => {
    try {
      const res = await axios.post(\`\${API_URL}/auth/register\`, { username, email, password, ageVerified });
      localStorage.setItem('token', res.data.token);
      set({ user: res.data.user, token: res.data.token, isAuthenticated: true });
      return true;
    } catch (error) {
      return false;
    }
  },
  
  checkAuth: async () => {
    const token = localStorage.getItem('token');
    if (!token) return;
    try {
      const res = await axios.get(\`\${API_URL}/auth/me\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ user: res.data, isAuthenticated: true });
    } catch {
      localStorage.removeItem('token');
      set({ isAuthenticated: false });
    }
  },
  
  logout: () => {
    localStorage.removeItem('token');
    set({ user: null, token: null, isAuthenticated: false });
  }
}));
EOF

cat > frontend/src/store/characterStore.js << 'EOF'
import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useCharacterStore = create((set, get) => ({
  characters: [],
  currentCharacter: null,
  
  fetchCharacters: async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(\`\${API_URL}/character/list\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ characters: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  fetchCharacter: async (id) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(\`\${API_URL}/character/\${id}\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ currentCharacter: res.data });
      return res.data;
    } catch (error) {
      return null;
    }
  },
  
  createCharacter: async (data) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(\`\${API_URL}/character/create\`, data, { headers: { Authorization: \`Bearer \${token}\` } });
      await get().fetchCharacters();
      return res.data;
    } catch (error) {
      return null;
    }
  }
}));
EOF

cat > frontend/src/store/chatStore.js << 'EOF'
import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useChatStore = create((set) => ({
  messages: [],
  loading: false,
  
  fetchHistory: async (characterId) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(\`\${API_URL}/chat/history/\${characterId}\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ messages: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  sendMessage: async (characterId, content) => {
    set({ loading: true });
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(\`\${API_URL}/chat/send\`, { characterId, content }, { headers: { Authorization: \`Bearer \${token}\` } });
      set((state) => ({ messages: [...state.messages, res.data.userMessage, res.data.aiMessage], loading: false }));
      return res.data;
    } catch (error) {
      set({ loading: false });
      throw error;
    }
  }
}));
EOF

cat > frontend/src/store/groupChatStore.js << 'EOF'
import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useGroupChatStore = create((set) => ({
  groups: [],
  group: null,
  messages: [],
  loading: false,
  
  fetchGroups: async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(\`\${API_URL}/group/list\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ groups: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  fetchGroup: async (id) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(\`\${API_URL}/group/\${id}\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ group: res.data });
      return res.data;
    } catch (error) {
      return null;
    }
  },
  
  fetchHistory: async (groupId) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(\`\${API_URL}/group/\${groupId}/history\`, { headers: { Authorization: \`Bearer \${token}\` } });
      set({ messages: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  sendMessage: async (groupId, content) => {
    set({ loading: true });
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(\`\${API_URL}/group/\${groupId}/message\`, { content }, { headers: { Authorization: \`Bearer \${token}\` } });
      set((state) => ({ messages: [...state.messages, res.data.userMessage, res.data.aiMessage], loading: false }));
      return res.data;
    } catch (error) {
      set({ loading: false });
      throw error;
    }
  },
  
  createGroup: async (data) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(\`\${API_URL}/group/create\`, data, { headers: { Authorization: \`Bearer \${token}\` } });
      return res.data;
    } catch (error) {
      return null;
    }
  }
}));
EOF

mkdir -p frontend/src/pages

cat > frontend/src/pages/Login.jsx << 'EOF'
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Heart } from 'lucide-react';
import { useAuthStore } from '../store/authStore';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { login } = useAuthStore();

  const handleSubmit = async (e) => {
    e.preventDefault();
    const success = await login(email, password);
    if (success) {
      navigate('/');
    } else {
      setError('Invalid credentials');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-md bg-black/60 backdrop-blur-xl rounded-3xl p-8 border border-pink-500/30">
        <div className="text-center mb-8">
          <div className="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center mb-4">
            <Heart size={32} className="text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">Welcome Back</h1>
          <p className="text-pink-300 mt-2">Your AI boyfriend is waiting</p>
        </div>

        {error && <div className="mb-4 p-3 rounded-lg bg-red-500/20 text-red-300 text-sm">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-pink-300 text-sm block mb-2">Email</label>
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-pink-500" required />
          </div>
          <div>
            <label className="text-pink-300 text-sm block mb-2">Password</label>
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-pink-500" required />
          </div>
          <button type="submit" className="w-full py-4 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white font-bold text-lg hover:opacity-90 transition">Sign In</button>
        </form>

        <p className="text-center text-pink-300 mt-6">Don't have an account? <Link to="/register" className="text-white hover:underline">Create one</Link></p>
      </motion.div>
    </div>
  );
}
EOF

cat > frontend/src/pages/Register.jsx << 'EOF'
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Heart } from 'lucide-react';
import { useAuthStore } from '../store/authStore';

export default function Register() {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [ageVerified, setAgeVerified] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { register } = useAuthStore();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!ageVerified) {
      setError('You must be 18+ to use this app');
      return;
    }
    const success = await register(username, email, password, ageVerified);
    if (success) {
      navigate('/');
    } else {
      setError('Registration failed');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-md bg-black/60 backdrop-blur-xl rounded-3xl p-8 border border-pink-500/30">
        <div className="text-center mb-8">
          <div className="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center mb-4">
            <Heart size={32} className="text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">Create Account</h1>
          <p className="text-pink-300 mt-2">Start your AI relationship</p>
        </div>

        {error && <div className="mb-4 p-3 rounded-lg bg-red-500/20 text-red-300 text-sm">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-pink-300 text-sm block mb-2">Username</label>
            <input type="text" value={username} onChange={(e) => setUsername(e.target.value)} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-pink-500" required />
          </div>
          <div>
            <label className="text-pink-300 text-sm block mb-2">Email</label>
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-pink-500" required />
          </div>
          <div>
            <label className="text-pink-300 text-sm block mb-2">Password</label>
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-pink-500" required />
          </div>
          <label className="flex items-center gap-3 cursor-pointer">
            <input type="checkbox" checked={ageVerified} onChange={(e) => setAgeVerified(e.target.checked)} className="w-5 h-5 rounded border-pink-500/30 accent-pink-500" />
            <span className="text-pink-300 text-sm">I am 18 years or older</span>
          </label>
          <button type="submit" className="w-full py-4 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white font-bold text-lg hover:opacity-90 transition">Create Account</button>
        </form>

        <p className="text-center text-pink-300 mt-6">Already have an account? <Link to="/login" className="text-white hover:underline">Sign in</Link></p>
      </motion.div>
    </div>
  );
}
EOF

cat > frontend/src/pages/Dashboard.jsx << 'EOF'
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Plus, MessageCircle, Users, Crown, LogOut } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useCharacterStore } from '../store/characterStore';
import { useGroupChatStore } from '../store/groupChatStore';

export default function Dashboard() {
  const { logout, user } = useAuthStore();
  const { characters, fetchCharacters } = useCharacterStore();
  const { groups, fetchGroups } = useGroupChatStore();
  const [activeTab, setActiveTab] = useState('characters');

  useEffect(() => {
    fetchCharacters();
    fetchGroups();
  }, []);

  return (
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white">Welcome back</h1>
            <p className="text-pink-300">Your tier: {user?.subscription?.tier || 'free'}</p>
          </div>
          <button onClick={logout} className="p-3 rounded-xl bg-white/10 text-pink-300 hover:bg-white/20"><LogOut size={20} /></button>
        </div>

        <div className="flex gap-4 mb-6">
          <button onClick={() => setActiveTab('characters')} className={\`px-6 py-3 rounded-xl font-medium transition \${activeTab === 'characters' ? 'bg-pink-500 text-white' : 'bg-white/10 text-pink-300'}\`}>Characters ({characters.length})</button>
          <button onClick={() => setActiveTab('groups')} className={\`px-6 py-3 rounded-xl font-medium transition \${activeTab === 'groups' ? 'bg-pink-500 text-white' : 'bg-white/10 text-pink-300'}\`}>Group Chats ({groups.length})</button>
        </div>

        {activeTab === 'characters' ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {characters.map((char) => (
              <motion.div key={char._id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="bg-black/40 backdrop-blur-xl rounded-2xl p-6 border border-pink-500/30">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center text-3xl text-white font-bold mb-4">{char.name[0]}</div>
                <h3 className="text-xl font-bold text-white mb-1">{char.name}</h3>
                <p className="text-pink-400 text-sm mb-4">{char.personality?.type}</p>
                <Link to={\`/chat/\${char._id}\`} className="flex items-center justify-center gap-2 w-full py-3 rounded-xl bg-pink-500/20 text-pink-300 hover:bg-pink-500/30 transition"><MessageCircle size={18} /> Chat</Link>
              </motion.div>
            ))}
            <Link to="/create" className="bg-black/20 backdrop-blur-xl rounded-2xl p-6 border border-dashed border-pink-500/30 hover:border-pink-500/60 transition flex flex-col items-center justify-center text-pink-300 hover:text-white min-h-[250px]"><Plus size={48} className="mb-4" /><span className="font-medium">Create New Boyfriend</span></Link>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {groups.map((group) => (
              <motion.div key={group._id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="bg-black/40 backdrop-blur-xl rounded-2xl p-6 border border-pink-500/30">
                <div className="flex items-center gap-3 mb-4"><Users size={24} className="text-pink-400" /><h3 className="text-xl font-bold text-white">{group.name}</h3></div>
                <p className="text-pink-300 text-sm mb-4">{group.characters?.length} members</p>
                <Link to={\`/group/\${group._id}\`} className="flex items-center justify-center gap-2 w-full py-3 rounded-xl bg-pink-500/20 text-pink-300 hover:bg-pink-500/30 transition"><MessageCircle size={18} /> Open Chat</Link>
              </motion.div>
            ))}
            <Link to="/create-group" className="bg-black/20 backdrop-blur-xl rounded-2xl p-6 border border-dashed border-pink-500/30 hover:border-pink-500/60 transition flex flex-col items-center justify-center text-pink-300 hover:text-white min-h-[200px]"><Plus size={48} className="mb-4" /><span className="font-medium">Create Group Chat</span></Link>
          </div>
        )}
      </div>
    </div>
  );
}
EOF

cat > frontend/src/pages/Chat.jsx << 'EOF'
import { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, ArrowLeft, Heart, Flame } from 'lucide-react';
import { useChatStore } from '../store/chatStore';
import { useCharacterStore } from '../store/characterStore';

export default function Chat() {
  const { characterId } = useParams();
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);
  const { messages, loading, fetchHistory, sendMessage } = useChatStore();
  const { currentCharacter, fetchCharacter } = useCharacterStore();

  useEffect(() => {
    fetchCharacter(characterId);
    fetchHistory(characterId);
  }, [characterId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;
    await sendMessage(characterId, input);
    setInput('');
  };

  if (!currentCharacter) return <div className="text-white p-8">Loading...</div>;

  return (
    <div className="flex flex-col h-screen max-w-4xl mx-auto bg-black/40 backdrop-blur-xl">
      <div className="flex items-center gap-4 p-4 border-b border-pink-500/30 bg-black/60">
        <Link to="/" className="p-2 rounded-lg bg-white/10 text-pink-300 hover:bg-white/20"><ArrowLeft size={20} /></Link>
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center text-2xl text-white font-bold">{currentCharacter.name[0]}</div>
        <div>
          <h2 className="text-white font-bold">{currentCharacter.name}</h2>
          <div className="flex items-center gap-3 text-sm">
            <span className="text-pink-400 flex items-center gap-1"><Heart size={14} /> {currentCharacter.mood?.affection || 50}%</span>
            <span className="text-orange-400 flex items-center gap-1"><Flame size={14} /> {currentCharacter.mood?.arousal || 30}%</span>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <AnimatePresence>
          {messages.map((msg, idx) => (
            <motion.div key={msg._id || idx} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className={\`flex \${msg.role === 'user' ? 'justify-end' : 'justify-start'}\`}>
              <div className={\`max-w-[70%] rounded-2xl p-4 \${msg.role === 'user' ? 'bg-gradient-to-r from-pink-600 to-purple-600 text-white' : 'bg-white/10 text-pink-100 border border-pink-500/30'}\`}>
                <p className="whitespace-pre-wrap">{msg.content}</p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
        {loading && <div className="flex justify-start"><div className="bg-white/10 rounded-2xl p-4 text-pink-300"><span className="animate-pulse">{currentCharacter.name} is typing...</span></div></div>}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-4 border-t border-pink-500/30 bg-black/60">
        <div className="flex items-center gap-2">
          <textarea value={input} onChange={(e) => setInput(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), handleSend())} placeholder={\`Message \${currentCharacter.name}...\`} className="flex-1 bg-white/10 border border-pink-500/30 rounded-2xl px-4 py-3 text-white placeholder-pink-300/50 focus:outline-none focus:border-pink-500 resize-none" rows={1} />
          <button onClick={handleSend} disabled={loading || !input.trim()} className="p-3 rounded-full bg-gradient-to-r from-pink-600 to-purple-600 text-white hover:opacity-90 disabled:opacity-50"><Send size={20} /></button>
        </div>
      </div>
    </div>
  );
}
EOF

cat > frontend/src/pages/CharacterCreator.jsx << 'EOF'
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useCharacterStore } from '../store/characterStore';

const personalityTypes = [
  { id: 'romantic', label: 'Romantic', desc: 'Sweet, affectionate' },
  { id: 'dominant', label: 'Dominant', desc: 'Assertive, takes charge' },
  { id: 'playful', label: 'Playful', desc: 'Teasing, flirty' },
  { id: 'mysterious', label: 'Mysterious', desc: 'Enigmatic, intense' },
  { id: 'protective', label: 'Protective', desc: 'Caring, loyal' }
];

export default function CharacterCreator() {
  const navigate = useNavigate();
  const { createCharacter } = useCharacterStore();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    name: '', age: 25, personality: { type: 'romantic' },
    appearance: { height: "6'0", build: 'athletic', hairColor: 'black', eyeColor: 'blue', ethnicity: 'caucasian', style: 'casual' },
    backstory: ''
  });

  const handleCreate = async () => {
    const character = await createCharacter(formData);
    if (character) navigate(\`/chat/\${character._id}\`);
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="w-full max-w-lg bg-black/60 backdrop-blur-xl rounded-3xl p-8 border border-pink-500/30">
        <div className="flex items-center gap-2 mb-8">
          {[1, 2, 3].map(i => <div key={i} className={\`flex-1 h-2 rounded-full \${i <= step ? 'bg-pink-500' : 'bg-white/20'}\`} />)}
        </div>
        
        {step === 1 && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-white">What's his name?</h2>
            <input type="text" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} placeholder="Enter name..." className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white text-xl" />
            <input type="range" min="18" max="50" value={formData.age} onChange={(e) => setFormData({...formData, age: parseInt(e.target.value)})} className="w-full accent-pink-500" />
            <p className="text-pink-300 text-center">Age: {formData.age}</p>
          </div>
        )}
        
        {step === 2 && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-white">Choose personality</h2>
            <div className="grid grid-cols-1 gap-3">
              {personalityTypes.map((p) => (
                <button key={p.id} onClick={() => setFormData({...formData, personality: { type: p.id }})} className={\`p-4 rounded-xl border text-left \${formData.personality.type === p.id ? 'border-pink-500 bg-pink-500/20' : 'border-white/20'}\`}>
                  <h3 className="text-white font-bold">{p.label}</h3>
                  <p className="text-pink-300 text-sm">{p.desc}</p>
                </button>
              ))}
            </div>
          </div>
        )}
        
        {step === 3 && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-white">Appearance</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-pink-300">Build</label>
                <select value={formData.appearance.build} onChange={(e) => setFormData({...formData, appearance: {...formData.appearance, build: e.target.value}})} className="w-full bg-white/10 border border-pink-500/30 rounded-lg px-3 py-2 text-white mt-1">
                  {['slim', 'athletic', 'muscular', 'stocky'].map(b => <option key={b} value={b}>{b}</option>)}
                </select>
              </div>
              <div>
                <label className="text-pink-300">Hair Color</label>
                <input type="text" value={formData.appearance.hairColor} onChange={(e) => setFormData({...formData, appearance: {...formData.appearance, hairColor: e.target.value}})} className="w-full bg-white/10 border border-pink-500/30 rounded-lg px-3 py-2 text-white mt-1" />
              </div>
            </div>
            <textarea value={formData.backstory} onChange={(e) => setFormData({...formData, backstory: e.target.value})} placeholder="His backstory..." rows={3} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white" />
          </div>
        )}

        <div className="flex justify-between mt-8">
          {step > 1 && <button onClick={() => setStep(step - 1)} className="px-6 py-3 rounded-xl border border-pink-500/30 text-pink-300">Back</button>}
          {step < 3 ? <button onClick={() => setStep(step + 1)} className="ml-auto px-6 py-3 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white">Next</button> : <button onClick={handleCreate} className="ml-auto px-6 py-3 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white">Create</button>}
        </div>
      </motion.div>
    </div>
  );
}
EOF

cat > frontend/src/pages/GroupChat.jsx << 'EOF'
import { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Send, Users, ArrowLeft } from 'lucide-react';
import { useGroupChatStore } from '../store/groupChatStore';

export default function GroupChat() {
  const { groupId } = useParams();
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);
  const { group, messages, loading, fetchGroup, fetchHistory, sendMessage } = useGroupChatStore();

  useEffect(() => {
    fetchGroup(groupId);
    fetchHistory(groupId);
  }, [groupId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;
    await sendMessage(groupId, input);
    setInput('');
  };

  if (!group) return <div className="text-white p-8">Loading...</div>;

  return (
    <div className="flex flex-col h-screen max-w-4xl mx-auto bg-black/40 backdrop-blur-xl">
      <div className="flex items-center gap-4 p-4 border-b border-pink-500/30 bg-black/60">
        <Link to="/" className="p-2 rounded-lg bg-white/10 text-pink-300"><ArrowLeft size={20} /></Link>
        <Users size={24} className="text-pink-400" />
        <div><h2 className="text-white font-bold">{group.name}</h2><p className="text-pink-300 text-sm">{group.characters?.length} members</p></div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, idx) => (
          <motion.div key={idx} initial={{ opacity: 0 }} animate={{ opacity: 1 }} className={\`flex \${msg.role === 'user' ? 'justify-end' : 'justify-start'}\`}>
            <div className={\`max-w-[70%] rounded-2xl p-4 \${msg.role === 'user' ? 'bg-gradient-to-r from-pink-600 to-purple-600 text-white' : 'bg-white/10 text-pink-100'}\`}>
              {msg.characterId && <p className="text-pink-400 text-xs font-bold mb-1">{msg.characterId.name}</p>}
              <p>{msg.content}</p>
            </div>
          </motion.div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-4 border-t border-pink-500/30 bg-black/60">
        <div className="flex gap-2">
          <input value={input} onChange={(e) => setInput(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && handleSend()} placeholder="Message the group..." className="flex-1 bg-white/10 border border-pink-500/30 rounded-2xl px-4 py-3 text-white" />
          <button onClick={handleSend} disabled={loading} className="p-3 rounded-full bg-gradient-to-r from-pink-600 to-purple-600 text-white"><Send size={20} /></button>
        </div>
      </div>
    </div>
  );
}
EOF

cat > frontend/src/pages/CreateGroup.jsx << 'EOF'
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useCharacterStore } from '../store/characterStore';
import { useGroupChatStore } from '../store/groupChatStore';

export default function CreateGroup() {
  const navigate = useNavigate();
  const { characters, fetchCharacters } = useCharacterStore();
  const { createGroup } = useGroupChatStore();
  const [name, setName] = useState('');
  const [selectedChars, setSelectedChars] = useState([]);

  useEffect(() => { fetchCharacters(); }, []);

  const toggleChar = (id) => {
    setSelectedChars(prev => prev.includes(id) ? prev.filter(c => c !== id) : [...prev, id]);
  };

  const handleCreate = async () => {
    if (selectedChars.length < 2) return;
    const group = await createGroup({ name, characterIds: selectedChars });
    if (group) navigate(\`/group/\${group._id}\`);
  };

  return (
    <div className="min-h-screen p-8">
      <div className="max-w-2xl mx-auto bg-black/60 backdrop-blur-xl rounded-3xl p-8 border border-pink-500/30">
        <h1 className="text-3xl font-bold text-white mb-6">Create Group Chat</h1>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Group name..." className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white mb-6" />
        <p className="text-pink-300 mb-4">Select at least 2 characters:</p>
        <div className="grid grid-cols-2 gap-3 mb-6">
          {characters.map((char) => (
            <button key={char._id} onClick={() => toggleChar(char._id)} className={\`p-4 rounded-xl border-2 text-left \${selectedChars.includes(char._id) ? 'border-pink-500 bg-pink-500/20' : 'border-white/20'}\`}>
              <p className="text-white font-bold">{char.name}</p>
              <p className="text-pink-400 text-sm">{char.personality?.type}</p>
            </button>
          ))}
        </div>
        <button onClick={handleCreate} disabled={selectedChars.length < 2 || !name} className="w-full py-4 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white font-bold disabled:opacity-50">Create Group ({selectedChars.length} selected)</button>
      </div>
    </div>
  );
}
EOF

# Docker Compose
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:6-jammy
    restart: unless-stopped
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123

  backend:
    build: ./backend
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - MONGODB_URI=mongodb://admin:password123@mongodb:27017/ai-boyfriend?authSource=admin
      - JWT_SECRET=change_this_in_production
    depends_on:
      - mongodb

  frontend:
    build: ./frontend
    restart: unless-stopped
    ports:
      - "5173:80"

volumes:
  mongo_data:
EOF

# Create backend Dockerfile
cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
EOF

# Create frontend Dockerfile
cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Render config
cat > render.yaml << 'EOF'
services:
  - type: web
    name: ai-boyfriend-api
    runtime: node
    buildCommand: cd backend && npm install
    startCommand: cd backend && npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 10000
      - key: MONGODB_URI
        sync: false
      - key: JWT_SECRET
        generateValue: true

  - type: web
    name: ai-boyfriend-web
    runtime: static
    buildCommand: cd frontend && npm install && npm run build
    staticPublishPath: ./frontend/dist
    envVars:
      - key: VITE_API_URL
        value: https://ai-boyfriend-api.onrender.com
EOF

# README
cat > README.md << 'EOF'
# AI Boyfriend App

Complete AI companion application with chat, image generation, group chats, and more.

## Quick Start

### Local Development
```bash
# With Docker (Recommended)
docker-compose up

# Or manually
cd backend && npm install && npm start
cd frontend && npm install && npm run dev