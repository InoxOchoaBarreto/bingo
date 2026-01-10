import { useState, useEffect, useRef } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import { Game, GameParticipant, BingoCard as BingoCardType, CalledNumber, Room } from '../../types';
import { BingoCard } from './BingoCard';
import { checkWin } from '../../utils/bingoValidator';
import { ArrowLeft, Users, Trophy, Volume2, Coins, Award, CreditCard } from 'lucide-react';

interface GameRoomProps {
  roomId: string;
  onLeave: () => void;
}

export const GameRoom = ({ roomId, onLeave }: GameRoomProps) => {
  const { profile, refreshProfile } = useAuth();
  const [room, setRoom] = useState<Room | null>(null);
  const [game, setGame] = useState<Game | null>(null);
  const [participants, setParticipants] = useState<GameParticipant[]>([]);
  const [card, setCard] = useState<BingoCardType | null>(null);
  const [calledNumbers, setCalledNumbers] = useState<CalledNumber[]>([]);
  const [lastCalledNumber, setLastCalledNumber] = useState<CalledNumber | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [hasPaidEntry, setHasPaidEntry] = useState(false);
  const [showPurchaseModal, setShowPurchaseModal] = useState(false);
  const [purchasing, setPurchasing] = useState(false);
  const [claimingPrize, setClaimingPrize] = useState(false);
  const synth = useRef<SpeechSynthesis | null>(null);

  useEffect(() => {
    synth.current = window.speechSynthesis;
    return () => {
      synth.current?.cancel();
    };
  }, []);

  useEffect(() => {
    initializeGame();

    const gameSubscription = supabase
      .channel(`game_room_${roomId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'games', filter: `room_id=eq.${roomId}` }, (payload) => {
        if (payload.new) {
          setGame(payload.new as Game);
        }
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'game_participants' }, () => {
        loadParticipants();
      })
      .subscribe();

    return () => {
      gameSubscription.unsubscribe();
    };
  }, [roomId]);

  useEffect(() => {
    if (!game?.id) return;

    const calledNumbersSubscription = supabase
      .channel(`called_numbers_${game.id}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'called_numbers', filter: `game_id=eq.${game.id}` }, (payload) => {
        const newNumber = payload.new as CalledNumber;
        setCalledNumbers((prev) => [...prev, newNumber]);
        setLastCalledNumber(newNumber);
        speakNumber(newNumber);
      })
      .subscribe();

    loadCalledNumbers();

    return () => {
      calledNumbersSubscription.unsubscribe();
    };
  }, [game?.id]);

  const initializeGame = async () => {
    try {
      const { data: roomData, error: roomError } = await supabase
        .from('rooms')
        .select('*, game_mode:game_modes(*)')
        .eq('id', roomId)
        .single();

      if (roomError) throw roomError;
      setRoom(roomData);

      const { data: currentGame, error: gameError } = await supabase
        .from('games')
        .select('*')
        .eq('room_id', roomId)
        .in('status', ['waiting', 'in_progress'])
        .maybeSingle();

      if (gameError && gameError.code !== 'PGRST116') throw gameError;

      if (!currentGame) {
        await createNewGame();
      } else {
        setGame(currentGame);
        await loadParticipants();
        await joinGame(currentGame.id);
      }
    } catch (err: any) {
      console.error('Error initializing game:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const createNewGame = async () => {
    const { data: newGame, error } = await supabase
      .from('games')
      .insert({
        room_id: roomId,
        game_mode_id: room?.game_mode_id,
        status: 'waiting',
        entry_cost: room?.default_entry_cost || 10.00,
      })
      .select()
      .single();

    if (error) throw error;
    setGame(newGame);
    await joinGame(newGame.id);
  };

  const joinGame = async (gameId: string) => {
    if (!profile) return;

    const { data: existing } = await supabase
      .from('game_participants')
      .select('*')
      .eq('game_id', gameId)
      .eq('user_id', profile.id)
      .maybeSingle();

    if (!existing) {
      const { error: participantError } = await supabase
        .from('game_participants')
        .insert({
          game_id: gameId,
          user_id: profile.id,
          is_ready: true,
          paid_entry: false,
        });

      if (participantError) throw participantError;
      setHasPaidEntry(false);
      setShowPurchaseModal(true);
    } else {
      setHasPaidEntry(existing.paid_entry);
      if (!existing.paid_entry) {
        setShowPurchaseModal(true);
      } else {
        await getOrCreateCard(gameId);
      }
    }

    await loadParticipants();
  };

  const loadParticipants = async () => {
    if (!game?.id) return;

    const { data, error } = await supabase
      .from('game_participants')
      .select('*, user_profile:user_profiles(*)')
      .eq('game_id', game.id);

    if (error) {
      console.error('Error loading participants:', error);
      return;
    }

    setParticipants(data || []);
  };

  const getOrCreateCard = async (gameId: string) => {
    if (!profile) return;

    const { data: existingCard } = await supabase
      .from('bingo_cards')
      .select('*')
      .eq('game_id', gameId)
      .eq('user_id', profile.id)
      .maybeSingle();

    if (existingCard) {
      setCard(existingCard);
    } else {
      const numbers = generateBingoCard();
      const { data: newCard, error } = await supabase
        .from('bingo_cards')
        .insert({
          game_id: gameId,
          user_id: profile.id,
          numbers,
          marked_numbers: [],
        })
        .select()
        .single();

      if (error) throw error;
      setCard(newCard);
    }
  };

  const generateBingoCard = (): number[][] => {
    const card: number[][] = [];
    const ranges = [
      { min: 1, max: 15 },
      { min: 16, max: 30 },
      { min: 31, max: 45 },
      { min: 46, max: 60 },
      { min: 61, max: 75 },
    ];

    for (let col = 0; col < 5; col++) {
      const column: number[] = [];
      const usedNumbers = new Set<number>();

      while (column.length < 5) {
        const num = Math.floor(Math.random() * (ranges[col].max - ranges[col].min + 1)) + ranges[col].min;
        if (!usedNumbers.has(num)) {
          usedNumbers.add(num);
          column.push(num);
        }
      }
      card.push(column);
    }

    const transposed: number[][] = [];
    for (let row = 0; row < 5; row++) {
      transposed.push(card.map((col) => col[row]));
    }

    return transposed;
  };

  const loadCalledNumbers = async () => {
    if (!game?.id) return;

    const { data, error } = await supabase
      .from('called_numbers')
      .select('*')
      .eq('game_id', game.id)
      .order('order', { ascending: true });

    if (error) {
      console.error('Error loading called numbers:', error);
      return;
    }

    setCalledNumbers(data || []);
    if (data && data.length > 0) {
      setLastCalledNumber(data[data.length - 1]);
    }
  };

  const speakNumber = (calledNumber: CalledNumber) => {
    if (!synth.current) return;

    synth.current.cancel();

    const utterance = new SpeechSynthesisUtterance(
      `${calledNumber.letter} ${calledNumber.number}`
    );

    const voices = synth.current.getVoices();
    const femaleVoice = voices.find(
      (voice) => voice.lang.includes('es') && voice.name.toLowerCase().includes('female')
    ) || voices.find((voice) => voice.lang.includes('es'));

    if (femaleVoice) {
      utterance.voice = femaleVoice;
    }

    utterance.lang = 'es-ES';
    utterance.rate = 0.9;
    utterance.pitch = 1.1;

    synth.current.speak(utterance);
  };

  const handleMarkNumber = async (number: number) => {
    if (!card || !calledNumbers.some((cn) => cn.number === number)) return;

    const newMarkedNumbers = [...card.marked_numbers, number];

    const { error } = await supabase
      .from('bingo_cards')
      .update({ marked_numbers: newMarkedNumbers })
      .eq('id', card.id);

    if (error) {
      console.error('Error marking number:', error);
      return;
    }

    setCard({ ...card, marked_numbers: newMarkedNumbers });
  };

  const handleBingoCall = async () => {
    if (!card || !game || !room || !profile) return;

    const hasWon = checkWin(card, room.game_mode.pattern);

    if (!hasWon) {
      alert('Tu cartón no tiene el patrón ganador. Sigue jugando!');
      return;
    }

    const { error } = await supabase.rpc('finish_game_with_winner', {
      p_game_id: game.id,
      p_winner_id: profile.id,
      p_pattern: room.game_mode.pattern,
    });

    if (error) {
      console.error('Error declaring winner:', error);
      alert('Error al declarar victoria. Por favor intenta de nuevo.');
      return;
    }

    alert('¡BINGO! ¡Felicidades, has ganado!');
  };

  const handlePurchaseEntry = async () => {
    if (!game || !profile) return;

    setPurchasing(true);
    try {
      const { data, error } = await supabase.rpc('purchase_game_entry', {
        p_game_id: game.id,
        p_user_id: profile.id,
      });

      if (error) throw error;

      const result = data as { success: boolean; error?: string; new_balance?: number };

      if (!result.success) {
        alert(result.error || 'Error al comprar entrada');
        return;
      }

      setHasPaidEntry(true);
      setShowPurchaseModal(false);
      await refreshProfile();
      await getOrCreateCard(game.id);
      alert(`¡Entrada comprada! Tu nuevo balance es $${result.new_balance?.toFixed(2)}`);
    } catch (err: any) {
      console.error('Error purchasing entry:', err);
      alert('Error al comprar entrada. Por favor intenta de nuevo.');
    } finally {
      setPurchasing(false);
    }
  };

  const handleClaimPrize = async () => {
    if (!game || !profile) return;

    setClaimingPrize(true);
    try {
      const { data, error } = await supabase.rpc('claim_prize', {
        p_game_id: game.id,
        p_user_id: profile.id,
      });

      if (error) throw error;

      const result = data as { success: boolean; error?: string; prize_amount?: number; new_balance?: number };

      if (!result.success) {
        alert(result.error || 'Error al cobrar premio');
        return;
      }

      await refreshProfile();
      setGame({ ...game, prize_pool: 0 });
      alert(`¡Premio cobrado! Ganaste $${result.prize_amount?.toFixed(2)}. Tu nuevo balance es $${result.new_balance?.toFixed(2)}`);

      setTimeout(() => {
        onLeave();
      }, 2000);
    } catch (err: any) {
      console.error('Error claiming prize:', err);
      alert('Error al cobrar premio. Por favor intenta de nuevo.');
    } finally {
      setClaimingPrize(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-16 h-16 border-4 border-blue-600 border-t-transparent rounded-full mx-auto"></div>
          <p className="mt-4 text-gray-600 text-lg">Cargando sala de juego...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-600 text-lg mb-4">{error}</p>
          <button
            onClick={onLeave}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Volver al Lobby
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50 p-4">
      <div className="max-w-7xl mx-auto">
        <div className="flex justify-between items-center mb-6">
          <button
            onClick={onLeave}
            className="flex items-center gap-2 px-4 py-2 bg-white rounded-lg shadow hover:shadow-md transition"
          >
            <ArrowLeft className="w-5 h-5" />
            Salir
          </button>
          <div className="flex flex-col items-center">
            <h1 className="text-2xl font-bold text-gray-800">{room?.name}</h1>
            {profile && (
              <div className="flex items-center gap-2 text-green-600 mt-1">
                <Coins className="w-5 h-5" />
                <span className="text-lg font-bold">${profile.balance.toFixed(2)}</span>
              </div>
            )}
          </div>
          {game && (
            <div className="flex items-center gap-2 bg-yellow-50 px-4 py-2 rounded-lg">
              <Award className="w-5 h-5 text-yellow-600" />
              <div>
                <p className="text-xs text-gray-600">Premio</p>
                <p className="text-lg font-bold text-yellow-800">${game.prize_pool.toFixed(2)}</p>
              </div>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            {!hasPaidEntry ? (
              <div className="bg-white rounded-2xl shadow-xl p-8 text-center">
                <CreditCard className="w-16 h-16 text-blue-600 mx-auto mb-4" />
                <h3 className="text-2xl font-bold text-gray-800 mb-2">Compra tu Entrada</h3>
                <p className="text-gray-600 mb-6">
                  Necesitas comprar una entrada para jugar en esta sala
                </p>
                <button
                  onClick={() => setShowPurchaseModal(true)}
                  className="px-6 py-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition"
                >
                  Comprar Entrada
                </button>
              </div>
            ) : (
              <>
                {card && (
                  <BingoCard
                    card={card}
                    onMarkNumber={handleMarkNumber}
                    isDisabled={game?.status !== 'in_progress'}
                  />
                )}

                {game?.status === 'in_progress' && card && (
                  <button
                    onClick={handleBingoCall}
                    className="w-full py-4 bg-gradient-to-r from-yellow-500 to-yellow-600 text-white text-xl font-bold rounded-xl hover:from-yellow-600 hover:to-yellow-700 transition-all transform hover:scale-105 active:scale-95 shadow-lg"
                  >
                    ¡BINGO!
                  </button>
                )}

                {game?.status === 'finished' && game.winner_id === profile?.id && game.prize_pool > 0 && (
                  <button
                    onClick={handleClaimPrize}
                    disabled={claimingPrize}
                    className="w-full py-4 bg-gradient-to-r from-green-500 to-green-600 text-white text-xl font-bold rounded-xl hover:from-green-600 hover:to-green-700 transition-all transform hover:scale-105 active:scale-95 shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {claimingPrize ? 'Cobrando...' : `¡Cobrar Premio $${game.prize_pool.toFixed(2)}!`}
                  </button>
                )}
              </>
            )}

            {lastCalledNumber && (
              <div className="mt-6 bg-white rounded-2xl shadow-xl p-6">
                <div className="flex items-center gap-4 mb-4">
                  <Volume2 className="w-6 h-6 text-blue-600" />
                  <h3 className="text-xl font-bold text-gray-800">Último Número Cantado</h3>
                </div>
                <div className="flex items-center justify-center">
                  <div className="w-32 h-32 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-full flex flex-col items-center justify-center shadow-lg">
                    <span className="text-white text-2xl font-bold">{lastCalledNumber.letter}</span>
                    <span className="text-white text-4xl font-bold">{lastCalledNumber.number}</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-2xl shadow-xl p-6">
              <div className="flex items-center gap-2 mb-4">
                <Users className="w-6 h-6 text-blue-600" />
                <h3 className="text-xl font-bold text-gray-800">
                  Jugadores ({participants.length}/{room?.max_players})
                </h3>
              </div>
              <div className="space-y-2">
                {participants.map((participant) => (
                  <div
                    key={participant.id}
                    className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg"
                  >
                    <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold">
                      {participant.user_profile?.full_name.charAt(0)}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-800">
                        {participant.user_profile?.full_name}
                      </p>
                      <div className="flex items-center gap-3 text-sm text-gray-600">
                        <span className="flex items-center gap-1">
                          <Trophy className="w-3 h-3" />
                          {participant.user_profile?.wins || 0}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl shadow-xl p-6">
              <h3 className="text-xl font-bold text-gray-800 mb-4">Números Cantados</h3>
              <div className="grid grid-cols-5 gap-2 max-h-96 overflow-y-auto">
                {calledNumbers.map((cn) => (
                  <div
                    key={cn.id}
                    className="aspect-square bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex flex-col items-center justify-center text-white shadow"
                  >
                    <span className="text-xs font-bold">{cn.letter}</span>
                    <span className="text-lg font-bold">{cn.number}</span>
                  </div>
                ))}
              </div>
              {calledNumbers.length === 0 && (
                <p className="text-center text-gray-500 py-8">
                  Esperando que el juego comience...
                </p>
              )}
            </div>
          </div>
        </div>
      </div>

      {showPurchaseModal && game && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8">
            <div className="text-center mb-6">
              <CreditCard className="w-16 h-16 text-blue-600 mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-gray-800 mb-2">Comprar Entrada al Juego</h2>
              <p className="text-gray-600">
                Necesitas comprar una entrada para obtener tu tabla de bingo
              </p>
            </div>

            <div className="space-y-4 mb-6">
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <span className="text-gray-700">Tu Balance</span>
                <div className="flex items-center gap-2 text-green-600 font-bold">
                  <Coins className="w-5 h-5" />
                  <span>${profile?.balance.toFixed(2)}</span>
                </div>
              </div>

              <div className="flex items-center justify-between p-4 bg-blue-50 rounded-lg">
                <span className="text-gray-700">Costo de Entrada</span>
                <div className="flex items-center gap-2 text-blue-600 font-bold">
                  <Coins className="w-5 h-5" />
                  <span>${game.entry_cost.toFixed(2)}</span>
                </div>
              </div>

              <div className="flex items-center justify-between p-4 bg-yellow-50 rounded-lg">
                <span className="text-gray-700">Premio Acumulado</span>
                <div className="flex items-center gap-2 text-yellow-600 font-bold">
                  <Award className="w-5 h-5" />
                  <span>${game.prize_pool.toFixed(2)}</span>
                </div>
              </div>

              {profile && profile.balance < game.entry_cost && (
                <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-red-700 text-sm text-center">
                    Balance insuficiente para comprar la entrada
                  </p>
                </div>
              )}
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => {
                  setShowPurchaseModal(false);
                  onLeave();
                }}
                className="flex-1 px-4 py-3 bg-gray-200 text-gray-800 rounded-lg font-semibold hover:bg-gray-300 transition"
                disabled={purchasing}
              >
                Cancelar
              </button>
              <button
                onClick={handlePurchaseEntry}
                disabled={purchasing || (profile && profile.balance < game.entry_cost)}
                className="flex-1 px-4 py-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {purchasing ? 'Comprando...' : 'Comprar Entrada'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
