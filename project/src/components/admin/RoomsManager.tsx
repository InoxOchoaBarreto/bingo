import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Room, GameMode } from '../../types';
import { Plus, Edit, Trash2, Users, Coins } from 'lucide-react';

export const RoomsManager = () => {
  const [rooms, setRooms] = useState<(Room & { game_mode: GameMode })[]>([]);
  const [gameModes, setGameModes] = useState<GameMode[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editingRoom, setEditingRoom] = useState<Room | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    game_mode_id: '',
    max_players: 10,
    min_players: 3,
    default_entry_cost: 10.00,
    is_active: true,
  });

  useEffect(() => {
    loadRooms();
    loadGameModes();
  }, []);

  const loadRooms = async () => {
    const { data, error } = await supabase
      .from('rooms')
      .select('*, game_mode:game_modes(*)')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading rooms:', error);
      return;
    }

    setRooms(data || []);
  };

  const loadGameModes = async () => {
    const { data, error } = await supabase
      .from('game_modes')
      .select('*')
      .eq('active', true)
      .order('name');

    if (error) {
      console.error('Error loading game modes:', error);
      return;
    }

    setGameModes(data || []);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (editingRoom) {
      const { error } = await supabase
        .from('rooms')
        .update(formData)
        .eq('id', editingRoom.id);

      if (error) {
        console.error('Error updating room:', error);
        return;
      }
    } else {
      const { error } = await supabase.from('rooms').insert(formData);

      if (error) {
        console.error('Error creating room:', error);
        return;
      }
    }

    resetForm();
    loadRooms();
  };

  const handleEdit = (room: Room) => {
    setEditingRoom(room);
    setFormData({
      name: room.name,
      game_mode_id: room.game_mode_id,
      max_players: room.max_players,
      min_players: room.min_players,
      default_entry_cost: room.default_entry_cost,
      is_active: room.is_active,
    });
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('¿Estás seguro de eliminar esta sala?')) return;

    const { error } = await supabase.from('rooms').delete().eq('id', id);

    if (error) {
      console.error('Error deleting room:', error);
      return;
    }

    loadRooms();
  };

  const resetForm = () => {
    setFormData({
      name: '',
      game_mode_id: '',
      max_players: 10,
      min_players: 3,
      default_entry_cost: 10.00,
      is_active: true,
    });
    setEditingRoom(null);
    setShowForm(false);
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Gestión de Salas</h2>
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          <Plus className="w-5 h-5" />
          Nueva Sala
        </button>
      </div>

      {showForm && (
        <div className="mb-6 p-6 bg-gray-50 rounded-lg border-2 border-gray-200">
          <h3 className="text-lg font-bold text-gray-800 mb-4">
            {editingRoom ? 'Editar Sala' : 'Nueva Sala'}
          </h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Nombre de la Sala
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Modo de Juego
              </label>
              <select
                value={formData.game_mode_id}
                onChange={(e) => setFormData({ ...formData, game_mode_id: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                required
              >
                <option value="">Seleccionar modo</option>
                {gameModes.map((mode) => (
                  <option key={mode.id} value={mode.id}>
                    {mode.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Mínimo de Jugadores
                </label>
                <input
                  type="number"
                  min="2"
                  value={formData.min_players}
                  onChange={(e) =>
                    setFormData({ ...formData, min_players: parseInt(e.target.value) })
                  }
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Máximo de Jugadores
                </label>
                <input
                  type="number"
                  min="2"
                  value={formData.max_players}
                  onChange={(e) =>
                    setFormData({ ...formData, max_players: parseInt(e.target.value) })
                  }
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Costo de Entrada por Defecto
              </label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-semibold">
                  $
                </span>
                <input
                  type="number"
                  step="0.01"
                  min="0.01"
                  value={formData.default_entry_cost}
                  onChange={(e) =>
                    setFormData({ ...formData, default_entry_cost: parseFloat(e.target.value) })
                  }
                  className="w-full pl-8 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Este será el costo de entrada para los juegos en esta sala
              </p>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="is_active"
                checked={formData.is_active}
                onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
              <label htmlFor="is_active" className="text-sm font-medium text-gray-700">
                Sala activa
              </label>
            </div>

            <div className="flex gap-3">
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                {editingRoom ? 'Actualizar' : 'Crear'}
              </button>
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {rooms.map((room) => (
          <div
            key={room.id}
            className="p-4 bg-white border border-gray-200 rounded-lg hover:shadow-md transition"
          >
            <div className="flex justify-between items-start mb-3">
              <div>
                <h3 className="font-bold text-gray-800">{room.name}</h3>
                <p className="text-sm text-gray-600">{room.game_mode.name}</p>
              </div>
              <span
                className={`px-2 py-1 text-xs font-semibold rounded ${
                  room.is_active
                    ? 'bg-green-100 text-green-700'
                    : 'bg-gray-100 text-gray-700'
                }`}
              >
                {room.is_active ? 'Activa' : 'Inactiva'}
              </span>
            </div>

            <div className="space-y-2 mb-3">
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Users className="w-4 h-4" />
                <span>
                  {room.min_players} - {room.max_players} jugadores
                </span>
              </div>
              <div className="flex items-center gap-2 text-sm text-green-600">
                <Coins className="w-4 h-4" />
                <span className="font-semibold">
                  Entrada: ${room.default_entry_cost.toFixed(2)}
                </span>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => handleEdit(room)}
                className="flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-sm"
              >
                <Edit className="w-4 h-4" />
                Editar
              </button>
              <button
                onClick={() => handleDelete(room.id)}
                className="flex items-center gap-1 px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-sm"
              >
                <Trash2 className="w-4 h-4" />
                Eliminar
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
