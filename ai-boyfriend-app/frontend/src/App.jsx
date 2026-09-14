import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { useAuthStore } from './store/authStore';

import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Chat from './pages/Chat';
import CharacterCreator from './pages/CharacterCreator';
import GroupChat from './pages/GroupChat';
import CreateGroup from './pages/CreateGroup';

function PrivateRoute({ children }) {
  const { isAuthenticated } = useAuthStore();
  return isAuthenticated ? children : <Navigate to="/login" />;
}

function App() {
  const { checkAuth } = useAuthStore();
  useEffect(() => { checkAuth(); }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-pink-900 to-red-900">
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/" element={<PrivateRoute><Dashboard /></PrivateRoute>} />
        <Route path="/chat/:characterId" element={<PrivateRoute><Chat /></PrivateRoute>} />
        <Route path="/create" element={<PrivateRoute><CharacterCreator /></PrivateRoute>} />
        <Route path="/group/:groupId" element={<PrivateRoute><GroupChat /></PrivateRoute>} />
        <Route path="/create-group" element={<PrivateRoute><CreateGroup /></PrivateRoute>} />
      </Routes>
    </div>
  );
}

export default App;
