import { useState } from 'react';
import { ArrowLeft, Home, Users, Settings as SettingsIcon, Play } from 'lucide-react';
import { RoomsManager } from './RoomsManager';
import { GameModesManager } from './GameModesManager';
import { UsersManager } from './UsersManager';
import { GameController } from './GameController';

interface AdminPanelProps {
  onBack: () => void;
}

type Tab = 'rooms' | 'modes' | 'users' | 'games';

export const AdminPanel = ({ onBack }: AdminPanelProps) => {
  const [activeTab, setActiveTab] = useState<Tab>('rooms');

  const tabs = [
    { id: 'rooms' as Tab, label: 'Salas', icon: Home },
    { id: 'modes' as Tab, label: 'Modos de Juego', icon: SettingsIcon },
    { id: 'users' as Tab, label: 'Usuarios', icon: Users },
    { id: 'games' as Tab, label: 'Control de Juegos', icon: Play },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-8">
          <div className="flex items-center gap-4">
            <button
              onClick={onBack}
              className="flex items-center gap-2 px-4 py-2 bg-white rounded-lg shadow hover:shadow-md transition"
            >
              <ArrowLeft className="w-5 h-5" />
              Volver
            </button>
            <h1 className="text-3xl font-bold text-gray-800">Panel de Administración</h1>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-md mb-6">
          <div className="flex border-b">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-6 py-4 font-semibold transition-all ${
                    activeTab === tab.id
                      ? 'border-b-2 border-blue-600 text-blue-600'
                      : 'text-gray-600 hover:text-gray-800'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  {tab.label}
                </button>
              );
            })}
          </div>

          <div className="p-6">
            {activeTab === 'rooms' && <RoomsManager />}
            {activeTab === 'modes' && <GameModesManager />}
            {activeTab === 'users' && <UsersManager />}
            {activeTab === 'games' && <GameController />}
          </div>
        </div>
      </div>
    </div>
  );
};
