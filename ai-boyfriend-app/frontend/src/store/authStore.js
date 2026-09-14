import { create } from 'zustand';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const useAuthStore = create((set) => ({
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: !!localStorage.getItem('token'),
  
  login: async (email, password) => {
    try {
      const res = await axios.post(`${API_URL}/auth/login`, { email, password });
      localStorage.setItem('token', res.data.token);
      set({ user: res.data.user, token: res.data.token, isAuthenticated: true });
      return true;
    } catch (error) {
      return false;
    }
  },
  
  register: async (username, email, password, ageVerified) => {
    try {
      const res = await axios.post(`${API_URL}/auth/register`, { username, email, password, ageVerified });
      localStorage.setItem('token', res.data.token);
      set({ user: res.data.user, token: res.data.token, isAuthenticated: true });
      return true;
    } catch (error) {
      return false;
    }
  },
  
  checkAuth: async () => {
    const token = localStorage.getItem('token');
    if (!token) return;
    try {
      const res = await axios.get(`${API_URL}/auth/me`, { headers: { Authorization: `Bearer ${token}` } });
      set({ user: res.data, isAuthenticated: true });
    } catch {
      localStorage.removeItem('token');
      set({ isAuthenticated: false });
    }
  },
  
  logout: () => {
    localStorage.removeItem('token');
    set({ user: null, token: null, isAuthenticated: false });
  }
}));
