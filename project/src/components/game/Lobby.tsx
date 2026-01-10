import { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import { Room, GameMode, Game } from '../../types';
import { Users, Trophy, LogOut, User as UserIcon, Settings, Edit, Coins, Award } from 'lucide-react';
import { ProfileEditor } from '../profile/ProfileEditor';

interface LobbyProps {
  onJoinRoom: (roomId: string) => void;
  onAdminPanel: () => void;
}

interface RoomWithGame extends Room {
  game_mode: GameMode;
  player_count: number;
  current_game: Game | null;
}

export const Lobby = ({ onJoinRoom, onAdminPanel }: LobbyProps) => {
  const { profile, signOut, refreshProfile } = useAuth();
  const [rooms, setRooms] = useState<RoomWithGame[]>([]);
  const [loading, setLoading] = useState(true);
  const [showProfileEditor, setShowProfileEditor] = useState(false);

  useEffect(() => {
    loadRooms();

    const subscription = supabase
      .channel('room_changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rooms' }, () => {
        loadRooms();
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const loadRooms = async () => {
    try {
      const { data: roomsData, error: roomsError } = await supabase
        .from('rooms')
        .select(`
          *,
          game_mode:game_modes(*)
        `)
        .eq('is_active', true)
        .order('created_at', { ascending: false });

      if (roomsError) throw roomsError;

      const roomsWithCounts = await Promise.all(
        (roomsData || []).map(async (room) => {
          const { data: currentGame } = await supabase
            .from('games')
            .select('*')
            .eq('room_id', room.id)
            .in('status', ['waiting', 'in_progress'])
            .maybeSingle();

          let playerCount = 0;
          if (currentGame) {
            const { count } = await supabase
              .from('game_participants')
              .select('*', { count: 'exact', head: true })
              .eq('game_id', currentGame.id);
            playerCount = count || 0;
          }

          return { ...room, player_count: playerCount, current_game: currentGame };
        })
      );

      setRooms(roomsWithCounts);
    } catch (error) {
      console.error('Error loading rooms:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-8">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-gradient-to-br from-blue-600 to-blue-700 rounded-xl flex items-center justify-center text-white font-bold text-xl shadow-lg">
              B
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-800">Bingo Multijugador</h1>
              <p className="text-gray-600">Selecciona una sala para jugar</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {profile?.role === 'admin' && (
              <button
                onClick={onAdminPanel}
                className="flex items-center gap-2 px-4 py-2 bg-gray-800 text-white rounded-lg hover:bg-gray-900 transition"
              >
                <Settings className="w-5 h-5" />
                Panel Admin
              </button>
            )}
            <button
              onClick={signOut}
              className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
            >
              <LogOut className="w-5 h-5" />
              Salir
            </button>
          </div>
        </div>

        {profile && (
          <div className="bg-white rounded-xl p-6 mb-8 shadow-md">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white">
                  <UserIcon className="w-8 h-8" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-xl font-bold text-gray-800">{profile.full_name}</h2>
                    <button
                      onClick={() => setShowProfileEditor(true)}
                      className="p-1 hover:bg-gray-100 rounded transition"
                      title="Editar perfil"
                    >
                      <Edit className="w-4 h-4 text-gray-600" />
                    </button>
                  </div>
                  <p className="text-gray-600">{profile.role === 'admin' ? 'Administrador' : 'Jugador'}</p>
                </div>
              </div>
              <div className="flex gap-8">
                <div className="text-center">
                  <div className="flex items-center gap-2 text-green-600 mb-1">
                    <Coins className="w-5 h-5" />
                    <span className="text-2xl font-bold">${profile.balance.toFixed(2)}</span>
                  </div>
                  <p className="text-sm text-gray-600">Balance</p>
                </div>
                <div className="text-center">
                  <div className="flex items-center gap-2 text-yellow-600 mb-1">
                    <Trophy className="w-5 h-5" />
                    <span className="text-2xl font-bold">{profile.wins}</span>
                  </div>
                  <p className="text-sm text-gray-600">Victorias</p>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-blue-600 mb-1">{profile.points}</div>
                  <p className="text-sm text-gray-600">Puntos</p>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-gray-800 mb-1">{profile.games_played}</div>
                  <p className="text-sm text-gray-600">Partidas</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full mx-auto"></div>
            <p className="mt-4 text-gray-600">Cargando salas...</p>
          </div>
        ) : rooms.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-xl shadow-md">
            <p className="text-gray-600 text-lg">No hay salas disponibles en este momento</p>
            <p className="text-gray-500 mt-2">Vuelve más tarde o contacta al administrador</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {rooms.map((room) => (
              <div
                key={room.id}
                className="bg-white rounded-xl shadow-md hover:shadow-xl transition-all p-6 border-2 border-transparent hover:border-blue-500"
              >
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-xl font-bold text-gray-800 mb-1">{room.name}</h3>
                    <p className="text-sm text-gray-600">{room.game_mode.name}</p>
                  </div>
                  <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                    <Users className="w-6 h-6 text-blue-600" />
                  </div>
                </div>

                <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                  {room.game_mode.description || 'Sin descripción'}
                </p>

                {room.current_game && (
                  <div className="grid grid-cols-2 gap-3 mb-4">
                    <div className="bg-green-50 rounded-lg p-3">
                      <div className="flex items-center gap-2 text-green-700 mb-1">
                        <Coins className="w-4 h-4" />
                        <span className="text-sm font-medium">Entrada</span>
                      </div>
                      <p className="text-lg font-bold text-green-800">
                        ${room.current_game.entry_cost.toFixed(2)}
                      </p>
                    </div>
                    <div className="bg-yellow-50 rounded-lg p-3">
                      <div className="flex items-center gap-2 text-yellow-700 mb-1">
                        <Award className="w-4 h-4" />
                        <span className="text-sm font-medium">Premio</span>
                      </div>
                      <p className="text-lg font-bold text-yellow-800">
                        ${room.current_game.prize_pool.toFixed(2)}
                      </p>
                    </div>
                  </div>
                )}

                <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                  <div className="flex items-center gap-2 text-sm">
                    <Users className="w-4 h-4 text-gray-500" />
                    <span className="text-gray-700 font-medium">
                      {room.player_count} / {room.max_players}
                    </span>
                  </div>
                  <button
                    onClick={() => onJoinRoom(room.id)}
                    className="px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg text-sm font-semibold hover:from-blue-700 hover:to-blue-800 transition-all"
                  >
                    Entrar a Sala
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {showProfileEditor && <ProfileEditor onClose={() => setShowProfileEditor(false)} />}
    </div>
  );
};
