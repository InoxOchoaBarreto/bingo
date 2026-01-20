import { useState } from 'react';
import { useAuth } from './contexts/AuthContext';
import { LoginForm } from './components/auth/LoginForm';
import { RegisterForm } from './components/auth/RegisterForm';
import { ForgotPasswordForm } from './components/auth/ForgotPasswordForm';
import { Lobby } from './components/game/Lobby';
import { GameRoom } from './components/game/GameRoom';
import { AdminPanel } from './components/admin/AdminPanel';

type AuthView = 'login' | 'register' | 'forgot-password';
type AppView = 'lobby' | 'game' | 'admin';

function App() {
  const { user, profile, loading } = useAuth();
  const [authView, setAuthView] = useState<AuthView>('login');
  const [appView, setAppView] = useState<AppView>('lobby');
  const [selectedRoomId, setSelectedRoomId] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-20 h-20 bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl flex items-center justify-center text-white font-bold text-3xl shadow-xl mb-4 mx-auto animate-pulse">
            B
          </div>
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Bingo Multijugador</h1>
          <div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full mx-auto"></div>
        </div>
      </div>
    );
  }

  if (!user || !profile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50 flex items-center justify-center p-4">
        {authView === 'login' && (
          <LoginForm
            onToggleForm={() => setAuthView('register')}
            onForgotPassword={() => setAuthView('forgot-password')}
          />
        )}
        {authView === 'register' && (
          <RegisterForm onToggleForm={() => setAuthView('login')} />
        )}
        {authView === 'forgot-password' && (
          <ForgotPasswordForm onBack={() => setAuthView('login')} />
        )}
      </div>
    );
  }

  const handleJoinRoom = (roomId: string) => {
    setSelectedRoomId(roomId);
    setAppView('game');
  };

  const handleLeaveRoom = () => {
    setSelectedRoomId(null);
    setAppView('lobby');
  };

  const handleAdminPanel = () => {
    setAppView('admin');
  };

  const handleBackToLobby = () => {
    setAppView('lobby');
  };

  if (appView === 'game' && selectedRoomId) {
    return <GameRoom roomId={selectedRoomId} onLeave={handleLeaveRoom} />;
  }

  if (appView === 'admin') {
    return <AdminPanel onBack={handleBackToLobby} />;
  }

  return <Lobby onJoinRoom={handleJoinRoom} onAdminPanel={handleAdminPanel} />;
}

export default App;
