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
      content: `${respondingChar.name}: Hey everyone! ${content}`,
      timestamp: new Date()
    });
    await aiMessage.save();

    res.json({ userMessage, aiMessage });
  } catch (error) {
    res.status(500).json({ error: 'Failed to send message' });
  }
});

export default router;
