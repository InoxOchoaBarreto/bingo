import { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import { UserProfile } from '../../types';
import { Trophy, Target, Users as UsersIcon, Coins, Edit, Plus, X } from 'lucide-react';

export const UsersManager = () => {
  const { profile: adminProfile } = useAuth();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingUser, setEditingUser] = useState<UserProfile | null>(null);
  const [addingBalanceUser, setAddingBalanceUser] = useState<UserProfile | null>(null);
  const [balanceAmount, setBalanceAmount] = useState('');
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading users:', error);
      return;
    }

    setUsers(data || []);
    setLoading(false);
  };

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser || !adminProfile) return;

    setProcessing(true);
    try {
      const { data, error } = await supabase.rpc('admin_update_profile', {
        p_admin_id: adminProfile.id,
        p_user_id: editingUser.id,
        p_full_name: editingUser.full_name,
        p_phone: editingUser.phone || '',
        p_role: editingUser.role,
      });

      if (error) throw error;

      const result = data as { success: boolean; error?: string };
      if (!result.success) {
        alert(result.error || 'Error al actualizar perfil');
        return;
      }

      setEditingUser(null);
      await loadUsers();
      alert('Perfil actualizado correctamente');
    } catch (err: any) {
      console.error('Error updating profile:', err);
      alert('Error al actualizar perfil');
    } finally {
      setProcessing(false);
    }
  };

  const handleAddBalance = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!addingBalanceUser || !adminProfile) return;

    const amount = parseFloat(balanceAmount);
    if (isNaN(amount) || amount <= 0) {
      alert('Ingresa un monto válido');
      return;
    }

    setProcessing(true);
    try {
      const { data, error } = await supabase.rpc('admin_add_balance', {
        p_admin_id: adminProfile.id,
        p_user_id: addingBalanceUser.id,
        p_amount: amount,
      });

      if (error) throw error;

      const result = data as { success: boolean; error?: string; new_balance?: number; amount_added?: number };
      if (!result.success) {
        alert(result.error || 'Error al agregar balance');
        return;
      }

      setAddingBalanceUser(null);
      setBalanceAmount('');
      await loadUsers();
      alert(`Se agregaron $${result.amount_added?.toFixed(2)} al usuario. Nuevo balance: $${result.new_balance?.toFixed(2)}`);
    } catch (err: any) {
      console.error('Error adding balance:', err);
      alert('Error al agregar balance');
    } finally {
      setProcessing(false);
    }
  };

  if (loading) {
    return (
      <div className="text-center py-12">
        <div className="animate-spin w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full mx-auto"></div>
        <p className="mt-4 text-gray-600">Cargando usuarios...</p>
      </div>
    );
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Gestión de Usuarios</h2>
        <div className="flex items-center gap-2 text-gray-600">
          <UsersIcon className="w-5 h-5" />
          <span className="font-semibold">{users.length} usuarios totales</span>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full bg-white rounded-lg overflow-hidden">
          <thead className="bg-gray-100">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                Usuario
              </th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                Teléfono
              </th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Rol</th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-700">
                Balance
              </th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-700">
                Victorias
              </th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-700">
                Puntos
              </th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-700">
                Partidas
              </th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-700">
                Acciones
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50 transition">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold">
                      {user.full_name.charAt(0)}
                    </div>
                    <div>
                      <p className="font-medium text-gray-800">{user.full_name}</p>
                      <p className="text-sm text-gray-500">{user.id.substring(0, 8)}...</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 text-gray-700">{user.phone || '-'}</td>
                <td className="px-6 py-4">
                  <span
                    className={`px-2 py-1 text-xs font-semibold rounded ${
                      user.role === 'admin'
                        ? 'bg-purple-100 text-purple-700'
                        : 'bg-blue-100 text-blue-700'
                    }`}
                  >
                    {user.role === 'admin' ? 'Admin' : 'Jugador'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center justify-center gap-1 text-green-600">
                    <Coins className="w-4 h-4" />
                    <span className="font-semibold">${user.balance.toFixed(2)}</span>
                  </div>
                </td>
                <td className="px-6 py-4 text-center">
                  <div className="flex items-center justify-center gap-1 text-yellow-600">
                    <Trophy className="w-4 h-4" />
                    <span className="font-semibold">{user.wins}</span>
                  </div>
                </td>
                <td className="px-6 py-4 text-center">
                  <div className="flex items-center justify-center gap-1 text-blue-600">
                    <Target className="w-4 h-4" />
                    <span className="font-semibold">{user.points}</span>
                  </div>
                </td>
                <td className="px-6 py-4 text-center">
                  <span className="font-semibold text-gray-700">{user.games_played}</span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex justify-center gap-2">
                    <button
                      onClick={() => setEditingUser({ ...user })}
                      className="p-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition"
                      title="Editar perfil"
                    >
                      <Edit className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => setAddingBalanceUser(user)}
                      className="p-2 bg-green-100 text-green-700 rounded-lg hover:bg-green-200 transition"
                      title="Agregar balance"
                    >
                      <Plus className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {editingUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-2xl font-bold text-gray-800">Editar Usuario</h3>
              <button
                onClick={() => setEditingUser(null)}
                className="p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleUpdateProfile} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nombre Completo
                </label>
                <input
                  type="text"
                  value={editingUser.full_name}
                  onChange={(e) => setEditingUser({ ...editingUser, full_name: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Teléfono
                </label>
                <input
                  type="tel"
                  value={editingUser.phone || ''}
                  onChange={(e) => setEditingUser({ ...editingUser, phone: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Rol
                </label>
                <select
                  value={editingUser.role}
                  onChange={(e) => setEditingUser({ ...editingUser, role: e.target.value as 'player' | 'admin' })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="player">Jugador</option>
                  <option value="admin">Administrador</option>
                </select>
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => setEditingUser(null)}
                  className="flex-1 px-4 py-3 bg-gray-200 text-gray-800 rounded-lg font-semibold hover:bg-gray-300 transition"
                  disabled={processing}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={processing}
                  className="flex-1 px-4 py-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {processing ? 'Guardando...' : 'Guardar Cambios'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {addingBalanceUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-2xl font-bold text-gray-800">Agregar Balance</h3>
              <button
                onClick={() => {
                  setAddingBalanceUser(null);
                  setBalanceAmount('');
                }}
                className="p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="mb-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold text-lg">
                  {addingBalanceUser.full_name.charAt(0)}
                </div>
                <div>
                  <p className="font-bold text-gray-800">{addingBalanceUser.full_name}</p>
                  <div className="flex items-center gap-2 text-green-600">
                    <Coins className="w-4 h-4" />
                    <span className="text-sm font-semibold">
                      Balance actual: ${addingBalanceUser.balance.toFixed(2)}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <form onSubmit={handleAddBalance} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Monto a Agregar
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-semibold">
                    $
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    value={balanceAmount}
                    onChange={(e) => setBalanceAmount(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg text-lg font-semibold focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="0.00"
                    required
                  />
                </div>
                {balanceAmount && !isNaN(parseFloat(balanceAmount)) && parseFloat(balanceAmount) > 0 && (
                  <p className="mt-2 text-sm text-gray-600">
                    Nuevo balance: ${(addingBalanceUser.balance + parseFloat(balanceAmount)).toFixed(2)}
                  </p>
                )}
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => {
                    setAddingBalanceUser(null);
                    setBalanceAmount('');
                  }}
                  className="flex-1 px-4 py-3 bg-gray-200 text-gray-800 rounded-lg font-semibold hover:bg-gray-300 transition"
                  disabled={processing}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={processing}
                  className="flex-1 px-4 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-semibold hover:from-green-700 hover:to-green-800 transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {processing ? 'Agregando...' : 'Agregar Balance'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
