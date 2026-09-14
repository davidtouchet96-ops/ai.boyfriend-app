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
