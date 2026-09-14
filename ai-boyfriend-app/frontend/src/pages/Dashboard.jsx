import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Plus, MessageCircle, Users, Crown, LogOut } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useCharacterStore } from '../store/characterStore';
import { useGroupChatStore } from '../store/groupChatStore';

export default function Dashboard() {
  const { logout, user } = useAuthStore();
  const { characters, fetchCharacters } = useCharacterStore();
  const { groups, fetchGroups } = useGroupChatStore();
  const [activeTab, setActiveTab] = useState('characters');

  useEffect(() => {
    fetchCharacters();
    fetchGroups();
  }, []);

  return (
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white">Welcome back</h1>
            <p className="text-pink-300">Your tier: {user?.subscription?.tier || 'free'}</p>
          </div>
          <button onClick={logout} className="p-3 rounded-xl bg-white/10 text-pink-300 hover:bg-white/20"><LogOut size={20} /></button>
        </div>

        <div className="flex gap-4 mb-6">
          <button onClick={() => setActiveTab('characters')} className={`px-6 py-3 rounded-xl font-medium transition ${activeTab === 'characters' ? 'bg-pink-500 text-white' : 'bg-white/10 text-pink-300'}`}>Characters ({characters.length})</button>
          <button onClick={() => setActiveTab('groups')} className={`px-6 py-3 rounded-xl font-medium transition ${activeTab === 'groups' ? 'bg-pink-500 text-white' : 'bg-white/10 text-pink-300'}`}>Group Chats ({groups.length})</button>
        </div>

        {activeTab === 'characters' ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {characters.map((char) => (
              <motion.div key={char._id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="bg-black/40 backdrop-blur-xl rounded-2xl p-6 border border-pink-500/30">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center text-3xl text-white font-bold mb-4">{char.name[0]}</div>
                <h3 className="text-xl font-bold text-white mb-1">{char.name}</h3>
                <p className="text-pink-400 text-sm mb-4">{char.personality?.type}</p>
                <Link to={`/chat/${char._id}`} className="flex items-center justify-center gap-2 w-full py-3 rounded-xl bg-pink-500/20 text-pink-300 hover:bg-pink-500/30 transition"><MessageCircle size={18} /> Chat</Link>
              </motion.div>
            ))}
            <Link to="/create" className="bg-black/20 backdrop-blur-xl rounded-2xl p-6 border border-dashed border-pink-500/30 hover:border-pink-500/60 transition flex flex-col items-center justify-center text-pink-300 hover:text-white min-h-[250px]"><Plus size={48} className="mb-4" /><span className="font-medium">Create New Boyfriend</span></Link>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {groups.map((group) => (
              <motion.div key={group._id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="bg-black/40 backdrop-blur-xl rounded-2xl p-6 border border-pink-500/30">
                <div className="flex items-center gap-3 mb-4"><Users size={24} className="text-pink-400" /><h3 className="text-xl font-bold text-white">{group.name}</h3></div>
                <p className="text-pink-300 text-sm mb-4">{group.characters?.length} members</p>
                <Link to={`/group/${group._id}`} className="flex items-center justify-center gap-2 w-full py-3 rounded-xl bg-pink-500/20 text-pink-300 hover:bg-pink-500/30 transition"><MessageCircle size={18} /> Open Chat</Link>
              </motion.div>
            ))}
            <Link to="/create-group" className="bg-black/20 backdrop-blur-xl rounded-2xl p-6 border border-dashed border-pink-500/30 hover:border-pink-500/60 transition flex flex-col items-center justify-center text-pink-300 hover:text-white min-h-[200px]"><Plus size={48} className="mb-4" /><span className="font-medium">Create Group Chat</span></Link>
          </div>
        )}
      </div>
    </div>
  );
}
