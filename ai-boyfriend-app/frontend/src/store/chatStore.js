import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useChatStore = create((set) => ({
  messages: [],
  loading: false,
  
  fetchHistory: async (characterId) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/chat/history/${characterId}`, { headers: { Authorization: `Bearer ${token}` } });
      set({ messages: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  sendMessage: async (characterId, content) => {
    set({ loading: true });
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(`${API_URL}/chat/send`, { characterId, content }, { headers: { Authorization: `Bearer ${token}` } });
      set((state) => ({ messages: [...state.messages, res.data.userMessage, res.data.aiMessage], loading: false }));
      return res.data;
    } catch (error) {
      set({ loading: false });
      throw error;
    }
  }
}));
