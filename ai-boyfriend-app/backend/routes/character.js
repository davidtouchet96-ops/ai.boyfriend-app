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
