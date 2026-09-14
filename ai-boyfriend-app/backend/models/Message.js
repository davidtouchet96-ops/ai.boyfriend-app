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
