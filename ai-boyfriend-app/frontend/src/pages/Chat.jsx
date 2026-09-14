import { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, ArrowLeft, Heart, Flame } from 'lucide-react';
import { useChatStore } from '../store/chatStore';
import { useCharacterStore } from '../store/characterStore';

export default function Chat() {
  const { characterId } = useParams();
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);
  const { messages, loading, fetchHistory, sendMessage } = useChatStore();
  const { currentCharacter, fetchCharacter } = useCharacterStore();

  useEffect(() => {
    fetchCharacter(characterId);
    fetchHistory(characterId);
  }, [characterId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;
    await sendMessage(characterId, input);
    setInput('');
  };

  if (!currentCharacter) return <div className="text-white p-8">Loading...</div>;

  return (
    <div className="flex flex-col h-screen max-w-4xl mx-auto bg-black/40 backdrop-blur-xl">
      <div className="flex items-center gap-4 p-4 border-b border-pink-500/30 bg-black/60">
        <Link to="/" className="p-2 rounded-lg bg-white/10 text-pink-300 hover:bg-white/20"><ArrowLeft size={20} /></Link>
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center text-2xl text-white font-bold">{currentCharacter.name[0]}</div>
        <div>
          <h2 className="text-white font-bold">{currentCharacter.name}</h2>
          <div className="flex items-center gap-3 text-sm">
            <span className="text-pink-400 flex items-center gap-1"><Heart size={14} /> {currentCharacter.mood?.affection || 50}%</span>
            <span className="text-orange-400 flex items-center gap-1"><Flame size={14} /> {currentCharacter.mood?.arousal || 30}%</span>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <AnimatePresence>
          {messages.map((msg, idx) => (
            <motion.div key={msg._id || idx} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[70%] rounded-2xl p-4 ${msg.role === 'user' ? 'bg-gradient-to-r from-pink-600 to-purple-600 text-white' : 'bg-white/10 text-pink-100 border border-pink-500/30'}`}>
                <p className="whitespace-pre-wrap">{msg.content}</p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
        {loading && <div className="flex justify-start"><div className="bg-white/10 rounded-2xl p-4 text-pink-300"><span className="animate-pulse">{currentCharacter.name} is typing...</span></div></div>}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-4 border-t border-pink-500/30 bg-black/60">
        <div className="flex items-center gap-2">
          <textarea value={input} onChange={(e) => setInput(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), handleSend())} placeholder={`Message ${currentCharacter.name}...`} className="flex-1 bg-white/10 border border-pink-500/30 rounded-2xl px-4 py-3 text-white placeholder-pink-300/50 focus:outline-none focus:border-pink-500 resize-none" rows={1} />
          <button onClick={handleSend} disabled={loading || !input.trim()} className="p-3 rounded-full bg-gradient-to-r from-pink-600 to-purple-600 text-white hover:opacity-90 disabled:opacity-50"><Send size={20} /></button>
        </div>
      </div>
    </div>
  );
}
