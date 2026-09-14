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
