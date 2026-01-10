import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { GameMode } from '../../types';
import { Plus, Edit, Trash2, Clock } from 'lucide-react';

export const GameModesManager = () => {
  const [modes, setModes] = useState<GameMode[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editingMode, setEditingMode] = useState<GameMode | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    pattern_type: 'horizontal_line',
    max_players: 10,
    ball_interval_seconds: 5,
    active: true,
  });

  useEffect(() => {
    loadModes();
  }, []);

  const loadModes = async () => {
    const { data, error } = await supabase
      .from('game_modes')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading game modes:', error);
      return;
    }

    setModes(data || []);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const modeData = {
      name: formData.name,
      description: formData.description,
      pattern: { type: formData.pattern_type },
      max_players: formData.max_players,
      ball_interval_seconds: formData.ball_interval_seconds,
      active: formData.active,
    };

    if (editingMode) {
      const { error } = await supabase
        .from('game_modes')
        .update(modeData)
        .eq('id', editingMode.id);

      if (error) {
        console.error('Error updating mode:', error);
        return;
      }
    } else {
      const { error } = await supabase.from('game_modes').insert(modeData);

      if (error) {
        console.error('Error creating mode:', error);
        return;
      }
    }

    resetForm();
    loadModes();
  };

  const handleEdit = (mode: GameMode) => {
    setEditingMode(mode);
    setFormData({
      name: mode.name,
      description: mode.description || '',
      pattern_type: mode.pattern.type,
      max_players: mode.max_players,
      ball_interval_seconds: mode.ball_interval_seconds,
      active: mode.active,
    });
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('¿Estás seguro de eliminar este modo de juego?')) return;

    const { error } = await supabase.from('game_modes').delete().eq('id', id);

    if (error) {
      console.error('Error deleting mode:', error);
      return;
    }

    loadModes();
  };

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      pattern_type: 'horizontal_line',
      max_players: 10,
      ball_interval_seconds: 5,
      active: true,
    });
    setEditingMode(null);
    setShowForm(false);
  };

  const patternTypes = [
    { value: 'horizontal_line', label: 'Línea Horizontal' },
    { value: 'vertical_line', label: 'Línea Vertical' },
    { value: 'diagonal', label: 'Diagonal' },
    { value: 'four_corners', label: '4 Esquinas' },
    { value: 'full_card', label: 'Bingo Completo' },
    { value: 'x_pattern', label: 'Patrón X' },
  ];

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Gestión de Modos de Juego</h2>
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          <Plus className="w-5 h-5" />
          Nuevo Modo
        </button>
      </div>

      {showForm && (
        <div className="mb-6 p-6 bg-gray-50 rounded-lg border-2 border-gray-200">
          <h3 className="text-lg font-bold text-gray-800 mb-4">
            {editingMode ? 'Editar Modo' : 'Nuevo Modo'}
          </h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Nombre</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Descripción</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                rows={3}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Tipo de Patrón
              </label>
              <select
                value={formData.pattern_type}
                onChange={(e) => setFormData({ ...formData, pattern_type: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                required
              >
                {patternTypes.map((type) => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-4">
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

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Intervalo de Bolas (segundos)
                </label>
                <input
                  type="number"
                  min="1"
                  value={formData.ball_interval_seconds}
                  onChange={(e) =>
                    setFormData({ ...formData, ball_interval_seconds: parseInt(e.target.value) })
                  }
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="active"
                checked={formData.active}
                onChange={(e) => setFormData({ ...formData, active: e.target.checked })}
                className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
              />
              <label htmlFor="active" className="text-sm font-medium text-gray-700">
                Modo activo
              </label>
            </div>

            <div className="flex gap-3">
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                {editingMode ? 'Actualizar' : 'Crear'}
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
        {modes.map((mode) => (
          <div
            key={mode.id}
            className="p-4 bg-white border border-gray-200 rounded-lg hover:shadow-md transition"
          >
            <div className="flex justify-between items-start mb-3">
              <div>
                <h3 className="font-bold text-gray-800">{mode.name}</h3>
                <p className="text-sm text-gray-600">{mode.description}</p>
              </div>
              <span
                className={`px-2 py-1 text-xs font-semibold rounded ${
                  mode.active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                }`}
              >
                {mode.active ? 'Activo' : 'Inactivo'}
              </span>
            </div>

            <div className="flex items-center gap-2 text-sm text-gray-600 mb-3">
              <Clock className="w-4 h-4" />
              <span>Intervalo: {mode.ball_interval_seconds}s</span>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => handleEdit(mode)}
                className="flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-sm"
              >
                <Edit className="w-4 h-4" />
                Editar
              </button>
              <button
                onClick={() => handleDelete(mode.id)}
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
