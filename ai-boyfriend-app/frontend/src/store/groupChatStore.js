import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useGroupChatStore = create((set) => ({
  groups: [],
  group: null,
  messages: [],
  loading: false,
  
  fetchGroups: async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/group/list`, { headers: { Authorization: `Bearer ${token}` } });
      set({ groups: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  fetchGroup: async (id) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/group/${id}`, { headers: { Authorization: `Bearer ${token}` } });
      set({ group: res.data });
      return res.data;
    } catch (error) {
      return null;
    }
  },
  
  fetchHistory: async (groupId) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/group/${groupId}/history`, { headers: { Authorization: `Bearer ${token}` } });
      set({ messages: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  sendMessage: async (groupId, content) => {
    set({ loading: true });
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(`${API_URL}/group/${groupId}/message`, { content }, { headers: { Authorization: `Bearer ${token}` } });
      set((state) => ({ messages: [...state.messages, res.data.userMessage, res.data.aiMessage], loading: false }));
      return res.data;
    } catch (error) {
      set({ loading: false });
      throw error;
    }
  },
  
  createGroup: async (data) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(`${API_URL}/group/create`, data, { headers: { Authorization: `Bearer ${token}` } });
      return res.data;
    } catch (error) {
      return null;
    }
  }
}));
