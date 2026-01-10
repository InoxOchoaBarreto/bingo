import { useState, useEffect, useRef } from 'react';
import { supabase } from '../../lib/supabase';
import { Game, Room, GameMode, GameParticipant } from '../../types';
import { Play, Pause, RotateCcw, Users, Trophy, Coins, Award } from 'lucide-react';

export const GameController = () => {
  const [games, setGames] = useState<
    (Game & { room: Room & { game_mode: GameMode }; participants: GameParticipant[] })[]
  >([]);
  const [selectedGame, setSelectedGame] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    loadGames();

    const subscription = supabase
      .channel('game_controller')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'games' }, () => {
        loadGames();
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  const loadGames = async () => {
    const { data: gamesData, error } = await supabase
      .from('games')
      .select(
        `
        *,
        room:rooms(*, game_mode:game_modes(*))
      `
      )
      .in('status', ['waiting', 'in_progress'])
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading games:', error);
      setLoading(false);
      return;
    }

    const gamesWithParticipants = await Promise.all(
      (gamesData || []).map(async (game) => {
        const { data: participants } = await supabase
          .from('game_participants')
          .select('*, user_profile:user_profiles(*)')
          .eq('game_id', game.id);

        return {
          ...game,
          participants: participants || [],
        };
      })
    );

    setGames(gamesWithParticipants);
    setLoading(false);
  };

  const startGame = async (gameId: string) => {
    const game = games.find((g) => g.id === gameId);
    if (!game) return;

    if (game.participants.length < (game.room.min_players || 3)) {
      alert(`Se necesitan al menos ${game.room.min_players || 3} jugadores para iniciar`);
      return;
    }

    const { error } = await supabase
      .from('games')
      .update({ status: 'in_progress', started_at: new Date().toISOString() })
      .eq('id', gameId);

    if (error) {
      console.error('Error starting game:', error);
      return;
    }

    setSelectedGame(gameId);
    startAutoCalling(gameId, game.room.game_mode.ball_interval_seconds);
    loadGames();
  };

  const pauseGame = (gameId: string) => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setSelectedGame(null);
  };

  const resumeGame = (gameId: string) => {
    const game = games.find((g) => g.id === gameId);
    if (!game) return;

    setSelectedGame(gameId);
    startAutoCalling(gameId, game.room.game_mode.ball_interval_seconds);
  };

  const startAutoCalling = (gameId: string, intervalSeconds: number) => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }

    intervalRef.current = setInterval(async () => {
      await callNextNumber(gameId);
    }, intervalSeconds * 1000);
  };

  const callNextNumber = async (gameId: string) => {
    const { data: calledNumbers } = await supabase
      .from('called_numbers')
      .select('number')
      .eq('game_id', gameId);

    const called = new Set((calledNumbers || []).map((cn) => cn.number));

    if (called.size >= 75) {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
      await supabase
        .from('games')
        .update({ status: 'finished', finished_at: new Date().toISOString() })
        .eq('id', gameId);
      return;
    }

    let number: number;
    do {
      number = Math.floor(Math.random() * 75) + 1;
    } while (called.has(number));

    const letter = getLetter(number);
    const order = called.size + 1;

    const { error } = await supabase.from('called_numbers').insert({
      game_id: gameId,
      number,
      letter,
      order,
    });

    if (error) {
      console.error('Error calling number:', error);
    }

    await supabase
      .from('games')
      .update({ current_ball: number })
      .eq('id', gameId);
  };

  const getLetter = (number: number): 'B' | 'I' | 'N' | 'G' | 'O' => {
    if (number <= 15) return 'B';
    if (number <= 30) return 'I';
    if (number <= 45) return 'N';
    if (number <= 60) return 'G';
    return 'O';
  };

  const finishGame = async (gameId: string, winnerId?: string) => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    let error;

    if (winnerId) {
      const result = await supabase.rpc('admin_finish_game_with_winner', {
        p_game_id: gameId,
        p_winner_id: winnerId,
      });
      error = result.error;
    } else {
      const result = await supabase.rpc('admin_finish_game_no_winner', {
        p_game_id: gameId,
      });
      error = result.error;
    }

    if (error) {
      console.error('Error finishing game:', error);
      alert('Error al finalizar el juego. Por favor intenta de nuevo.');
      return;
    }

    setSelectedGame(null);
    loadGames();
  };

  if (loading) {
    return (
      <div className="text-center py-12">
        <div className="animate-spin w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full mx-auto"></div>
        <p className="mt-4 text-gray-600">Cargando juegos...</p>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Control de Juegos</h2>
        <p className="text-gray-600">
          Gestiona las partidas activas y controla el desarrollo del juego
        </p>
      </div>

      {games.length === 0 ? (
        <div className="text-center py-12 bg-gray-50 rounded-lg">
          <p className="text-gray-600">No hay juegos activos en este momento</p>
        </div>
      ) : (
        <div className="space-y-4">
          {games.map((game) => (
            <div key={game.id} className="p-6 bg-white border border-gray-200 rounded-lg">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-xl font-bold text-gray-800">{game.room.name}</h3>
                  <p className="text-sm text-gray-600">{game.room.game_mode.name}</p>
                  <div className="flex items-center gap-4 mt-2">
                    <span
                      className={`px-2 py-1 text-xs font-semibold rounded ${
                        game.status === 'in_progress'
                          ? 'bg-green-100 text-green-700'
                          : 'bg-yellow-100 text-yellow-700'
                      }`}
                    >
                      {game.status === 'in_progress' ? 'En Progreso' : 'Esperando'}
                    </span>
                    <div className="flex items-center gap-1 text-sm text-gray-600">
                      <Users className="w-4 h-4" />
                      <span>{game.participants.length} jugadores</span>
                    </div>
                    <div className="flex items-center gap-1 text-sm text-green-600">
                      <Coins className="w-4 h-4" />
                      <span className="font-semibold">Entrada: ${game.entry_cost.toFixed(2)}</span>
                    </div>
                    <div className="flex items-center gap-1 text-sm text-yellow-600">
                      <Award className="w-4 h-4" />
                      <span className="font-semibold">Premio: ${game.prize_pool.toFixed(2)}</span>
                    </div>
                  </div>
                </div>

                <div className="flex gap-2">
                  {game.status === 'waiting' && (
                    <button
                      onClick={() => startGame(game.id)}
                      className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                    >
                      <Play className="w-4 h-4" />
                      Iniciar
                    </button>
                  )}
                  {game.status === 'in_progress' && selectedGame === game.id && (
                    <button
                      onClick={() => pauseGame(game.id)}
                      className="flex items-center gap-2 px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition"
                    >
                      <Pause className="w-4 h-4" />
                      Pausar
                    </button>
                  )}
                  {game.status === 'in_progress' && selectedGame !== game.id && (
                    <button
                      onClick={() => resumeGame(game.id)}
                      className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
                    >
                      <RotateCcw className="w-4 h-4" />
                      Reanudar
                    </button>
                  )}
                  <button
                    onClick={() => finishGame(game.id)}
                    className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
                  >
                    <Trophy className="w-4 h-4" />
                    Finalizar
                  </button>
                </div>
              </div>

              <div className="border-t border-gray-200 pt-4">
                <h4 className="font-semibold text-gray-700 mb-2">Participantes:</h4>
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
                  {game.participants.map((participant) => (
                    <div
                      key={participant.id}
                      className="flex items-center gap-2 p-2 bg-gray-50 rounded cursor-pointer hover:bg-gray-100 transition"
                      onClick={() => {
                        if (
                          confirm(
                            `¿Declarar a ${participant.user_profile?.full_name} como ganador?`
                          )
                        ) {
                          finishGame(game.id, participant.user_id);
                        }
                      }}
                    >
                      <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
                        {participant.user_profile?.full_name.charAt(0)}
                      </div>
                      <span className="text-sm text-gray-700 truncate">
                        {participant.user_profile?.full_name}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
