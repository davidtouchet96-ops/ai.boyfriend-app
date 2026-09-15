import express from 'express';
import { Message } from '../models/Message.js';
import { Character } from '../models/Character.js';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

const AI_BASE_URL = (process.env.AI_BASE_URL || 'https://api.openai.com/v1').replace(/\/$/, '');
const AI_MODEL = process.env.AI_MODEL || 'gpt-4o-mini';

async function generateAIReply({ character, history }) {
  if (!process.env.AI_API_KEY) {
    throw new Error('AI_API_KEY is not configured');
  }

  const personality = character.personality || `You are ${character.name}, a warm, engaging AI companion.`;

  const messages = [
    {
      role: 'system',
      content: `${personality}\n\nStay in character as ${character.name}. Respond naturally to the user's latest message. Do not repeat the user's message back verbatim. Keep the conversation engaging and conversational.`
    },
    ...history.map((message) => ({
      role: message.role === 'assistant' ? 'assistant' : 'user',
      content: message.content
    }))
  ];

  const response = await fetch(`${AI_BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${process.env.AI_API_KEY}`
    },
    body: JSON.stringify({
      model: AI_MODEL,
      messages,
      temperature: 0.9,
      max_tokens: 500
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`AI provider error (${response.status}): ${errorText.slice(0, 500)}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content?.trim();

  if (!reply) {
    throw new Error('AI provider returned an empty response');
  }

  return reply;
}

router.post('/send', authMiddleware, async (req, res) => {
  try {
    const { characterId, content } = req.body;

    if (!characterId || !content?.trim()) {
      return res.status(400).json({ error: 'Character and message are required' });
    }

    const character = await Character.findOne({ _id: characterId, userId: req.userId });
    if (!character) return res.status(404).json({ error: 'Character not found' });

    const userMessage = new Message({
      userId: req.userId,
      characterId,
      role: 'user',
      content: content.trim(),
      timestamp: new Date()
    });
    await userMessage.save();

    const previousMessages = await Message.find({
      userId: req.userId,
      characterId
    })
      .sort({ timestamp: -1 })
      .limit(30)
      .lean();

    const history = previousMessages
      .reverse()
      .map((message) => ({ role: message.role, content: message.content }));

    const aiReply = await generateAIReply({ character, history });

    const aiMessage = new Message({
      userId: req.userId,
      characterId,
      role: 'assistant',
      content: aiReply,
      timestamp: new Date()
    });
    await aiMessage.save();

    res.json({ userMessage, aiMessage });
  } catch (error) {
    console.error('Chat error:', error.message);
    res.status(500).json({ error: 'Failed to generate AI response' });
  }
});

router.get('/history/:characterId', authMiddleware, async (req, res) => {
  try {
    const messages = await Message.find({
      userId: req.userId,
      characterId: req.params.characterId
    }).sort({ timestamp: 1 }).limit(100);

    res.json(messages);
  } catch (error) {
    console.error('Chat history error:', error.message);
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

export default router;
