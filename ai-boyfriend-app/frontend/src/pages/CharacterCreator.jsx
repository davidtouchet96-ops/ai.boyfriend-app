import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useCharacterStore } from '../store/characterStore';

const personalityTypes = [
  { id: 'romantic', label: 'Romantic', desc: 'Sweet, affectionate' },
  { id: 'dominant', label: 'Dominant', desc: 'Assertive, takes charge' },
  { id: 'playful', label: 'Playful', desc: 'Teasing, flirty' },
  { id: 'mysterious', label: 'Mysterious', desc: 'Enigmatic, intense' },
  { id: 'protective', label: 'Protective', desc: 'Caring, loyal' }
];

export default function CharacterCreator() {
  const navigate = useNavigate();
  const { createCharacter } = useCharacterStore();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    name: '', age: 25, personality: { type: 'romantic' },
    appearance: { height: "6'0", build: 'athletic', hairColor: 'black', eyeColor: 'blue', ethnicity: 'caucasian', style: 'casual' },
    backstory: ''
  });

  const handleCreate = async () => {
    const character = await createCharacter(formData);
    if (character) navigate(`/chat/${character._id}`);
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="w-full max-w-lg bg-black/60 backdrop-blur-xl rounded-3xl p-8 border border-pink-500/30">
        <div className="flex items-center gap-2 mb-8">
          {[1, 2, 3].map(i => <div key={i} className={`flex-1 h-2 rounded-full ${i <= step ? 'bg-pink-500' : 'bg-white/20'}`} />)}
        </div>
        
        {step === 1 && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-white">What's his name?</h2>
            <input type="text" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} placeholder="Enter name..." className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white text-xl" />
            <input type="range" min="18" max="50" value={formData.age} onChange={(e) => setFormData({...formData, age: parseInt(e.target.value)})} className="w-full accent-pink-500" />
            <p className="text-pink-300 text-center">Age: {formData.age}</p>
          </div>
        )}
        
        {step === 2 && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-white">Choose personality</h2>
            <div className="grid grid-cols-1 gap-3">
              {personalityTypes.map((p) => (
                <button key={p.id} onClick={() => setFormData({...formData, personality: { type: p.id }})} className={`p-4 rounded-xl border text-left ${formData.personality.type === p.id ? 'border-pink-500 bg-pink-500/20' : 'border-white/20'}`}>
                  <h3 className="text-white font-bold">{p.label}</h3>
                  <p className="text-pink-300 text-sm">{p.desc}</p>
                </button>
              ))}
            </div>
          </div>
        )}
        
        {step === 3 && (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-white">Appearance</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-pink-300">Build</label>
                <select value={formData.appearance.build} onChange={(e) => setFormData({...formData, appearance: {...formData.appearance, build: e.target.value}})} className="w-full bg-white/10 border border-pink-500/30 rounded-lg px-3 py-2 text-white mt-1">
                  {['slim', 'athletic', 'muscular', 'stocky'].map(b => <option key={b} value={b}>{b}</option>)}
                </select>
              </div>
              <div>
                <label className="text-pink-300">Hair Color</label>
                <input type="text" value={formData.appearance.hairColor} onChange={(e) => setFormData({...formData, appearance: {...formData.appearance, hairColor: e.target.value}})} className="w-full bg-white/10 border border-pink-500/30 rounded-lg px-3 py-2 text-white mt-1" />
              </div>
            </div>
            <textarea value={formData.backstory} onChange={(e) => setFormData({...formData, backstory: e.target.value})} placeholder="His backstory..." rows={3} className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white" />
          </div>
        )}

        <div className="flex justify-between mt-8">
          {step > 1 && <button onClick={() => setStep(step - 1)} className="px-6 py-3 rounded-xl border border-pink-500/30 text-pink-300">Back</button>}
          {step < 3 ? <button onClick={() => setStep(step + 1)} className="ml-auto px-6 py-3 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white">Next</button> : <button onClick={handleCreate} className="ml-auto px-6 py-3 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white">Create</button>}
        </div>
      </motion.div>
    </div>
  );
}
