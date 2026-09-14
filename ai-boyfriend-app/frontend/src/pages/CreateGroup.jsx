import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useCharacterStore } from '../store/characterStore';
import { useGroupChatStore } from '../store/groupChatStore';

export default function CreateGroup() {
  const navigate = useNavigate();
  const { characters, fetchCharacters } = useCharacterStore();
  const { createGroup } = useGroupChatStore();
  const [name, setName] = useState('');
  const [selectedChars, setSelectedChars] = useState([]);

  useEffect(() => { fetchCharacters(); }, []);

  const toggleChar = (id) => {
    setSelectedChars(prev => prev.includes(id) ? prev.filter(c => c !== id) : [...prev, id]);
  };

  const handleCreate = async () => {
    if (selectedChars.length < 2) return;
    const group = await createGroup({ name, characterIds: selectedChars });
    if (group) navigate(`/group/${group._id}`);
  };

  return (
    <div className="min-h-screen p-8">
      <div className="max-w-2xl mx-auto bg-black/60 backdrop-blur-xl rounded-3xl p-8 border border-pink-500/30">
        <h1 className="text-3xl font-bold text-white mb-6">Create Group Chat</h1>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Group name..." className="w-full bg-white/10 border border-pink-500/30 rounded-xl px-4 py-3 text-white mb-6" />
        <p className="text-pink-300 mb-4">Select at least 2 characters:</p>
        <div className="grid grid-cols-2 gap-3 mb-6">
          {characters.map((char) => (
            <button key={char._id} onClick={() => toggleChar(char._id)} className={`p-4 rounded-xl border-2 text-left ${selectedChars.includes(char._id) ? 'border-pink-500 bg-pink-500/20' : 'border-white/20'}`}>
              <p className="text-white font-bold">{char.name}</p>
              <p className="text-pink-400 text-sm">{char.personality?.type}</p>
            </button>
          ))}
        </div>
        <button onClick={handleCreate} disabled={selectedChars.length < 2 || !name} className="w-full py-4 rounded-xl bg-gradient-to-r from-pink-600 to-purple-600 text-white font-bold disabled:opacity-50">Create Group ({selectedChars.length} selected)</button>
      </div>
    </div>
  );
}
