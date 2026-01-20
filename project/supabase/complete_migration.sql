/*
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                  BINGOS - Complete Database Migration                ║
  ║                                                                      ║
  ║  Proyecto: Sistema Multiplayer de Bingo con Apuestas                ║
  ║  Versión: 1.0                                                        ║
  ║  Fecha: 2026-01-15                                                   ║
  ╚══════════════════════════════════════════════════════════════════════╝

  Este script crea la estructura completa de la base de datos para el
  sistema de bingo multiplayer, incluyendo:

  ✓ Tablas con relaciones
  ✓ Políticas de seguridad RLS
  ✓ Funciones para lógica de negocio
  ✓ Índices para rendimiento
  ✓ Triggers para actualización automática

  IMPORTANTE: Ejecuta este script en un proyecto NUEVO de Supabase.
*/

-- ============================================================================
-- 1. TABLAS PRINCIPALES
-- ============================================================================

-- Tabla de perfiles de usuario (extiende auth.users)
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  phone text,
  role text NOT NULL DEFAULT 'player' CHECK (role IN ('player', 'admin')),
  points integer DEFAULT 0,
  wins integer DEFAULT 0,
  games_played integer DEFAULT 0,
  balance numeric(10, 2) DEFAULT 100.00 NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Modos de juego (patrones de victoria)
CREATE TABLE IF NOT EXISTS game_modes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  pattern jsonb NOT NULL,
  max_players integer DEFAULT 10,
  ball_interval_seconds integer DEFAULT 5,
  active boolean DEFAULT true,
  created_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Salas de juego
CREATE TABLE IF NOT EXISTS rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  game_mode_id uuid REFERENCES game_modes(id) ON DELETE CASCADE,
  max_players integer DEFAULT 10,
  min_players integer DEFAULT 3,
  is_active boolean DEFAULT true,
  default_entry_cost numeric(10, 2) DEFAULT 10.00 NOT NULL,
  created_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Partidas de juego
CREATE TABLE IF NOT EXISTS games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES rooms(id) ON DELETE CASCADE,
  game_mode_id uuid REFERENCES game_modes(id) ON DELETE CASCADE,
  status text DEFAULT 'waiting' CHECK (status IN ('waiting', 'in_progress', 'finished')),
  started_at timestamptz,
  finished_at timestamptz,
  winner_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  current_ball integer DEFAULT 0,
  entry_cost numeric(10, 2) DEFAULT 10.00 NOT NULL,
  prize_pool numeric(10, 2) DEFAULT 0.00 NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Participantes en juegos
CREATE TABLE IF NOT EXISTS game_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid REFERENCES games(id) ON DELETE CASCADE,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  is_ready boolean DEFAULT false,
  paid_entry boolean DEFAULT false NOT NULL,
  UNIQUE(game_id, user_id)
);

-- Tarjetas de bingo
CREATE TABLE IF NOT EXISTS bingo_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid REFERENCES games(id) ON DELETE CASCADE,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  numbers jsonb NOT NULL,
  marked_numbers jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(game_id, user_id)
);

-- Números cantados en cada juego
CREATE TABLE IF NOT EXISTS called_numbers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid REFERENCES games(id) ON DELETE CASCADE,
  number integer NOT NULL,
  letter text NOT NULL CHECK (letter IN ('B', 'I', 'N', 'G', 'O')),
  called_at timestamptz DEFAULT now(),
  "order" integer NOT NULL
);

-- Transacciones financieras
CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  game_id uuid REFERENCES games(id) ON DELETE SET NULL,
  type text NOT NULL CHECK (type IN ('deposit', 'entry_fee', 'prize_win', 'refund')),
  amount numeric(10, 2) NOT NULL,
  balance_after numeric(10, 2) NOT NULL,
  description text,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- ============================================================================
-- 2. ÍNDICES PARA RENDIMIENTO
-- ============================================================================

-- Índices para user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- Índices para rooms
CREATE INDEX IF NOT EXISTS idx_rooms_active ON rooms(is_active);
CREATE INDEX IF NOT EXISTS idx_rooms_created_by ON rooms(created_by);
CREATE INDEX IF NOT EXISTS idx_rooms_game_mode_id ON rooms(game_mode_id);

-- Índices para game_modes
CREATE INDEX IF NOT EXISTS idx_game_modes_created_by ON game_modes(created_by);

-- Índices para games
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_games_room_id ON games(room_id);
CREATE INDEX IF NOT EXISTS idx_games_game_mode_id ON games(game_mode_id);
CREATE INDEX IF NOT EXISTS idx_games_winner_id ON games(winner_id);

-- Índices para game_participants
CREATE INDEX IF NOT EXISTS idx_game_participants_game_id ON game_participants(game_id);
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id ON game_participants(user_id);

-- Índices para bingo_cards
CREATE INDEX IF NOT EXISTS idx_bingo_cards_game_user ON bingo_cards(game_id, user_id);
CREATE INDEX IF NOT EXISTS idx_bingo_cards_user_id ON bingo_cards(user_id);

-- Índices para called_numbers
CREATE INDEX IF NOT EXISTS idx_called_numbers_game_id ON called_numbers(game_id);

-- Índices para transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_game_id ON transactions(game_id);

-- ============================================================================
-- 3. HABILITAR ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_modes ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE bingo_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE called_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. POLÍTICAS RLS - USER_PROFILES
-- ============================================================================

CREATE POLICY "Users can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- ============================================================================
-- 5. POLÍTICAS RLS - GAME_MODES
-- ============================================================================

CREATE POLICY "Anyone can view active game modes"
  ON game_modes FOR SELECT
  TO authenticated
  USING (
    active = true
    OR created_by = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert game modes"
  ON game_modes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update game modes"
  ON game_modes FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete game modes"
  ON game_modes FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- ============================================================================
-- 6. POLÍTICAS RLS - ROOMS
-- ============================================================================

CREATE POLICY "Anyone can view active rooms"
  ON rooms FOR SELECT
  TO authenticated
  USING (
    is_active = true
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert rooms"
  ON rooms FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update rooms"
  ON rooms FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete rooms"
  ON rooms FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- ============================================================================
-- 7. POLÍTICAS RLS - GAMES
-- ============================================================================

CREATE POLICY "Users can view games they participate in"
  ON games FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM game_participants
      WHERE game_id = games.id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can create games"
  ON games FOR INSERT
  TO authenticated
  WITH CHECK (
    room_id IN (
      SELECT id FROM rooms WHERE is_active = true
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can update games"
  ON games FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM game_participants
      WHERE game_id = games.id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM game_participants
      WHERE game_id = games.id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete games"
  ON games FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- ============================================================================
-- 8. POLÍTICAS RLS - GAME_PARTICIPANTS
-- ============================================================================

CREATE POLICY "Users can view participants in their games"
  ON game_participants FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM game_participants gp
      WHERE gp.game_id = game_participants.game_id AND gp.user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "insert_own_participation"
  ON game_participants FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "update_own_participation"
  ON game_participants FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "admin_delete_participation"
  ON game_participants FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- ============================================================================
-- 9. POLÍTICAS RLS - BINGO_CARDS
-- ============================================================================

CREATE POLICY "Users can view cards"
  ON bingo_cards FOR SELECT
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM game_participants
      WHERE game_id = bingo_cards.game_id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own cards"
  ON bingo_cards FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own cards"
  ON bingo_cards FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================================================
-- 10. POLÍTICAS RLS - CALLED_NUMBERS
-- ============================================================================

CREATE POLICY "Users can view called numbers in their games"
  ON called_numbers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM game_participants
      WHERE game_id = called_numbers.game_id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert called numbers"
  ON called_numbers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- ============================================================================
-- 11. POLÍTICAS RLS - TRANSACTIONS
-- ============================================================================

CREATE POLICY "view_own_transactions"
  ON transactions FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ============================================================================
-- 12. FUNCIONES Y TRIGGERS
-- ============================================================================

-- Función para actualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Trigger para user_profiles
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Función para crear perfiles automáticamente al registrarse
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO user_profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.raw_user_meta_data->>'phone',
    'player'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Trigger para crear perfil automáticamente
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Función para comprar entrada a un juego
CREATE OR REPLACE FUNCTION purchase_game_entry(
  p_game_id uuid,
  p_user_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_entry_cost numeric;
  v_user_balance numeric;
  v_new_balance numeric;
  v_participant_exists boolean;
  v_already_paid boolean;
BEGIN
  SELECT entry_cost INTO v_entry_cost
  FROM games
  WHERE id = p_game_id;

  IF v_entry_cost IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Game not found');
  END IF;

  SELECT balance INTO v_user_balance
  FROM user_profiles
  WHERE id = p_user_id;

  IF v_user_balance < v_entry_cost THEN
    RETURN json_build_object('success', false, 'error', 'Insufficient balance');
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM game_participants
    WHERE game_id = p_game_id AND user_id = p_user_id
  ) INTO v_participant_exists;

  IF v_participant_exists THEN
    SELECT paid_entry INTO v_already_paid
    FROM game_participants
    WHERE game_id = p_game_id AND user_id = p_user_id;

    IF v_already_paid THEN
      RETURN json_build_object('success', false, 'error', 'Already purchased entry');
    END IF;
  END IF;

  v_new_balance := v_user_balance - v_entry_cost;

  UPDATE user_profiles
  SET balance = v_new_balance
  WHERE id = p_user_id;

  UPDATE games
  SET prize_pool = prize_pool + v_entry_cost
  WHERE id = p_game_id;

  IF v_participant_exists THEN
    UPDATE game_participants
    SET paid_entry = true
    WHERE game_id = p_game_id AND user_id = p_user_id;
  ELSE
    INSERT INTO game_participants (game_id, user_id, paid_entry)
    VALUES (p_game_id, p_user_id, true);
  END IF;

  INSERT INTO transactions (user_id, game_id, type, amount, balance_after, description)
  VALUES (
    p_user_id,
    p_game_id,
    'entry_fee',
    -v_entry_cost,
    v_new_balance,
    'Purchased bingo card'
  );

  RETURN json_build_object(
    'success', true,
    'new_balance', v_new_balance,
    'entry_cost', v_entry_cost
  );
END;
$$;

-- Función para reclamar premio
CREATE OR REPLACE FUNCTION claim_prize(
  p_game_id uuid,
  p_user_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_prize_pool numeric;
  v_user_balance numeric;
  v_new_balance numeric;
  v_game_status text;
  v_winner_id uuid;
BEGIN
  SELECT status, winner_id, prize_pool INTO v_game_status, v_winner_id, v_prize_pool
  FROM games
  WHERE id = p_game_id;

  IF v_game_status IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Game not found');
  END IF;

  IF v_game_status != 'finished' THEN
    RETURN json_build_object('success', false, 'error', 'Game not finished yet');
  END IF;

  IF v_winner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'error', 'You are not the winner');
  END IF;

  IF v_prize_pool <= 0 THEN
    RETURN json_build_object('success', false, 'error', 'Prize already claimed');
  END IF;

  SELECT balance INTO v_user_balance
  FROM user_profiles
  WHERE id = p_user_id;

  v_new_balance := v_user_balance + v_prize_pool;

  UPDATE user_profiles
  SET balance = v_new_balance
  WHERE id = p_user_id;

  UPDATE games
  SET prize_pool = 0
  WHERE id = p_game_id;

  INSERT INTO transactions (user_id, game_id, type, amount, balance_after, description)
  VALUES (
    p_user_id,
    p_game_id,
    'prize_win',
    v_prize_pool,
    v_new_balance,
    'Won bingo game'
  );

  RETURN json_build_object(
    'success', true,
    'prize_amount', v_prize_pool,
    'new_balance', v_new_balance
  );
END;
$$;

-- Función para que admins agreguen balance a usuarios
CREATE OR REPLACE FUNCTION admin_add_balance(
  p_admin_id uuid,
  p_user_id uuid,
  p_amount numeric
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_admin_role text;
  v_current_balance numeric;
  v_new_balance numeric;
BEGIN
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;

  IF v_admin_role IS NULL OR v_admin_role != 'admin' THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized: Admin access required');
  END IF;

  IF p_amount <= 0 THEN
    RETURN json_build_object('success', false, 'error', 'Amount must be positive');
  END IF;

  SELECT balance INTO v_current_balance
  FROM user_profiles
  WHERE id = p_user_id;

  IF v_current_balance IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;

  v_new_balance := v_current_balance + p_amount;

  UPDATE user_profiles
  SET balance = v_new_balance
  WHERE id = p_user_id;

  INSERT INTO transactions (user_id, type, amount, balance_after, description)
  VALUES (
    p_user_id,
    'deposit',
    p_amount,
    v_new_balance,
    'Balance added by admin'
  );

  RETURN json_build_object(
    'success', true,
    'new_balance', v_new_balance,
    'amount_added', p_amount
  );
END;
$$;

-- Función para que admins actualicen perfiles
CREATE OR REPLACE FUNCTION admin_update_profile(
  p_admin_id uuid,
  p_user_id uuid,
  p_full_name text,
  p_phone text,
  p_role text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_admin_role text;
BEGIN
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;

  IF v_admin_role IS NULL OR v_admin_role != 'admin' THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized: Admin access required');
  END IF;

  IF p_role NOT IN ('player', 'admin') THEN
    RETURN json_build_object('success', false, 'error', 'Invalid role');
  END IF;

  UPDATE user_profiles
  SET
    full_name = p_full_name,
    phone = p_phone,
    role = p_role,
    updated_at = now()
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;

  RETURN json_build_object('success', true);
END;
$$;

/*
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                      MIGRACIÓN COMPLETADA                            ║
  ╚══════════════════════════════════════════════════════════════════════╝

  ✅ Todas las tablas creadas
  ✅ Índices aplicados
  ✅ RLS habilitado en todas las tablas
  ✅ Políticas de seguridad configuradas
  ✅ Funciones de negocio instaladas
  ✅ Triggers configurados

  PRÓXIMOS PASOS:
  1. Actualiza tu archivo .env con las nuevas credenciales
  2. Crea un usuario y hazlo admin
  3. Prueba la aplicación

  ¡Tu base de datos está lista para usar!
*/
