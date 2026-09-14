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
