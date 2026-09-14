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
