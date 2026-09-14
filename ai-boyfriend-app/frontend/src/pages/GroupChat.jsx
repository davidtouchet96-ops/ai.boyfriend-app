import { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Send, Users, ArrowLeft } from 'lucide-react';
import { useGroupChatStore } from '../store/groupChatStore';

export default function GroupChat() {
  const { groupId } = useParams();
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);
  const { group, messages, loading, fetchGroup, fetchHistory, sendMessage } = useGroupChatStore();

  useEffect(() => {
    fetchGroup(groupId);
    fetchHistory(groupId);
  }, [groupId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;
    await sendMessage(groupId, input);
    setInput('');
  };

  if (!group) return <div className="text-white p-8">Loading...</div>;

  return (
    <div className="flex flex-col h-screen max-w-4xl mx-auto bg-black/40 backdrop-blur-xl">
      <div className="flex items-center gap-4 p-4 border-b border-pink-500/30 bg-black/60">
        <Link to="/" className="p-2 rounded-lg bg-white/10 text-pink-300"><ArrowLeft size={20} /></Link>
        <Users size={24} className="text-pink-400" />
        <div><h2 className="text-white font-bold">{group.name}</h2><p className="text-pink-300 text-sm">{group.characters?.length} members</p></div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, idx) => (
          <motion.div key={idx} initial={{ opacity: 0 }} animate={{ opacity: 1 }} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[70%] rounded-2xl p-4 ${msg.role === 'user' ? 'bg-gradient-to-r from-pink-600 to-purple-600 text-white' : 'bg-white/10 text-pink-100'}`}>
              {msg.characterId && <p className="text-pink-400 text-xs font-bold mb-1">{msg.characterId.name}</p>}
              <p>{msg.content}</p>
            </div>
          </motion.div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-4 border-t border-pink-500/30 bg-black/60">
        <div className="flex gap-2">
          <input value={input} onChange={(e) => setInput(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && handleSend()} placeholder="Message the group..." className="flex-1 bg-white/10 border border-pink-500/30 rounded-2xl px-4 py-3 text-white" />
          <button onClick={handleSend} disabled={loading} className="p-3 rounded-full bg-gradient-to-r from-pink-600 to-purple-600 text-white"><Send size={20} /></button>
        </div>
      </div>
    </div>
  );
}
