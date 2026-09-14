import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useCharacterStore = create((set, get) => ({
  characters: [],
  currentCharacter: null,
  
  fetchCharacters: async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/character/list`, { headers: { Authorization: `Bearer ${token}` } });
      set({ characters: res.data });
      return res.data;
    } catch (error) {
      return [];
    }
  },
  
  fetchCharacter: async (id) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/character/${id}`, { headers: { Authorization: `Bearer ${token}` } });
      set({ currentCharacter: res.data });
      return res.data;
    } catch (error) {
      return null;
    }
  },
  
  createCharacter: async (data) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post(`${API_URL}/character/create`, data, { headers: { Authorization: `Bearer ${token}` } });
      await get().fetchCharacters();
      return res.data;
    } catch (error) {
      return null;
    }
  }
}));
