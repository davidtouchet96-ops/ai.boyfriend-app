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
