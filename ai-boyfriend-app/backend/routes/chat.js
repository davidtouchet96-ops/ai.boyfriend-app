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
      content: `Hey babe! ${character.name} here. You said: "${content}" - I'm always here for you ❤️`,
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
