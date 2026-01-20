/*
  # Fix Database Security Issues

  1. Performance Optimizations
    - Add missing indexes for foreign keys:
      - bingo_cards.user_id
      - game_modes.created_by
      - games.game_mode_id
      - games.winner_id
      - rooms.created_by
      - rooms.game_mode_id
    
  2. RLS Policy Optimizations
    - Wrap all auth.uid() calls with SELECT to prevent re-evaluation per row
    - Consolidate multiple permissive SELECT policies on bingo_cards
    - Fix unrestricted access policy on games table
    
  3. Function Security
    - Set secure search_path on all functions to prevent SQL injection
    
  4. Notes
    - Auth DB Connection Strategy and Leaked Password Protection must be configured in Supabase dashboard
    - Unused indexes are kept as they may be needed for query performance
*/

-- ============================================
-- 1. ADD MISSING FOREIGN KEY INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_bingo_cards_user_id 
  ON public.bingo_cards(user_id);

CREATE INDEX IF NOT EXISTS idx_game_modes_created_by 
  ON public.game_modes(created_by);

CREATE INDEX IF NOT EXISTS idx_games_game_mode_id 
  ON public.games(game_mode_id);

CREATE INDEX IF NOT EXISTS idx_games_winner_id 
  ON public.games(winner_id);

CREATE INDEX IF NOT EXISTS idx_rooms_created_by 
  ON public.rooms(created_by);

CREATE INDEX IF NOT EXISTS idx_rooms_game_mode_id 
  ON public.rooms(game_mode_id);

-- ============================================
-- 2. FIX RLS POLICIES - USE SELECT WRAPPER
-- ============================================

-- Drop and recreate user_profiles policies
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

CREATE POLICY "Users can insert own profile"
  ON public.user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- Drop and recreate game_modes policies
DROP POLICY IF EXISTS "Anyone can view active game modes" ON public.game_modes;
DROP POLICY IF EXISTS "Admins can insert game modes" ON public.game_modes;
DROP POLICY IF EXISTS "Admins can update game modes" ON public.game_modes;
DROP POLICY IF EXISTS "Admins can delete game modes" ON public.game_modes;

CREATE POLICY "Anyone can view active game modes"
  ON public.game_modes
  FOR SELECT
  TO authenticated
  USING (
    active = true 
    OR created_by = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert game modes"
  ON public.game_modes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update game modes"
  ON public.game_modes
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete game modes"
  ON public.game_modes
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- Drop and recreate rooms policies
DROP POLICY IF EXISTS "Anyone can view active rooms" ON public.rooms;
DROP POLICY IF EXISTS "Admins can insert rooms" ON public.rooms;
DROP POLICY IF EXISTS "Admins can update rooms" ON public.rooms;
DROP POLICY IF EXISTS "Admins can delete rooms" ON public.rooms;

CREATE POLICY "Anyone can view active rooms"
  ON public.rooms
  FOR SELECT
  TO authenticated
  USING (
    is_active = true 
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert rooms"
  ON public.rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update rooms"
  ON public.rooms
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete rooms"
  ON public.rooms
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- Drop and recreate games policies (fixing unrestricted access)
DROP POLICY IF EXISTS "Users can view games they participate in" ON public.games;
DROP POLICY IF EXISTS "Admins can insert games" ON public.games;
DROP POLICY IF EXISTS "System can update games" ON public.games;
DROP POLICY IF EXISTS "Users can create games" ON public.games;
DROP POLICY IF EXISTS "Users can update games" ON public.games;
DROP POLICY IF EXISTS "Admins can delete games" ON public.games;

CREATE POLICY "Users can view games they participate in"
  ON public.games
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = games.id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can create games"
  ON public.games
  FOR INSERT
  TO authenticated
  WITH CHECK (
    room_id IN (
      SELECT id FROM public.rooms WHERE is_active = true
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- FIX: Restrict game updates properly
CREATE POLICY "Users can update games"
  ON public.games
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = games.id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = games.id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete games"
  ON public.games
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- Drop and consolidate bingo_cards policies
DROP POLICY IF EXISTS "Users can view cards in their games" ON public.bingo_cards;
DROP POLICY IF EXISTS "Users can view own cards" ON public.bingo_cards;
DROP POLICY IF EXISTS "Users can view cards in same game" ON public.bingo_cards;
DROP POLICY IF EXISTS "Users can create their own cards" ON public.bingo_cards;
DROP POLICY IF EXISTS "Users can create own cards" ON public.bingo_cards;
DROP POLICY IF EXISTS "Users can update their own cards" ON public.bingo_cards;
DROP POLICY IF EXISTS "Users can update own cards" ON public.bingo_cards;

-- Consolidate SELECT policies into one
CREATE POLICY "Users can view cards"
  ON public.bingo_cards
  FOR SELECT
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = bingo_cards.game_id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own cards"
  ON public.bingo_cards
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own cards"
  ON public.bingo_cards
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- Fix called_numbers policies
DROP POLICY IF EXISTS "Users can view called numbers in their games" ON public.called_numbers;
DROP POLICY IF EXISTS "System can insert called numbers" ON public.called_numbers;
DROP POLICY IF EXISTS "Admins can insert called numbers" ON public.called_numbers;

CREATE POLICY "Users can view called numbers in their games"
  ON public.called_numbers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.game_participants
      WHERE game_id = called_numbers.game_id AND user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert called numbers"
  ON public.called_numbers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- Fix game_participants policies
DROP POLICY IF EXISTS "Users can view participants in their games" ON public.game_participants;
DROP POLICY IF EXISTS "Users can join games" ON public.game_participants;
DROP POLICY IF EXISTS "Users can update their participation status" ON public.game_participants;
DROP POLICY IF EXISTS "insert_own_participation" ON public.game_participants;
DROP POLICY IF EXISTS "update_own_participation" ON public.game_participants;
DROP POLICY IF EXISTS "admin_delete_participation" ON public.game_participants;

CREATE POLICY "Users can view participants in their games"
  ON public.game_participants
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.game_participants gp
      WHERE gp.game_id = game_participants.game_id AND gp.user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "insert_own_participation"
  ON public.game_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "update_own_participation"
  ON public.game_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "admin_delete_participation"
  ON public.game_participants
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

-- Fix transactions policies
DROP POLICY IF EXISTS "view_own_transactions" ON public.transactions;

CREATE POLICY "view_own_transactions"
  ON public.transactions
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ============================================
-- 3. FIX FUNCTION SECURITY - SET SEARCH_PATH
-- ============================================

-- Drop functions before recreating with search_path
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.finish_game_with_winner(uuid, uuid);
DROP FUNCTION IF EXISTS public.admin_finish_game_with_winner(uuid, uuid);
DROP FUNCTION IF EXISTS public.admin_finish_game_no_winner(uuid);
DROP FUNCTION IF EXISTS public.purchase_game_entry(uuid, uuid);
DROP FUNCTION IF EXISTS public.claim_prize(uuid);
DROP FUNCTION IF EXISTS public.admin_add_balance(uuid, numeric, text);
DROP FUNCTION IF EXISTS public.admin_update_profile(uuid, text, numeric);

-- Recreate update_updated_at_column with search_path
CREATE FUNCTION public.update_updated_at_column()
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

-- Recreate trigger
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Recreate finish_game_with_winner with search_path
CREATE FUNCTION public.finish_game_with_winner(
  p_game_id uuid,
  p_winner_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.games
  SET 
    status = 'completed',
    winner_id = p_winner_id,
    finished_at = now()
  WHERE id = p_game_id;
END;
$$;

-- Recreate admin_finish_game_with_winner with search_path
CREATE FUNCTION public.admin_finish_game_with_winner(
  p_game_id uuid,
  p_winner_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can finish games';
  END IF;
  
  UPDATE public.games
  SET 
    status = 'completed',
    winner_id = p_winner_id,
    finished_at = now()
  WHERE id = p_game_id;
END;
$$;

-- Recreate admin_finish_game_no_winner with search_path
CREATE FUNCTION public.admin_finish_game_no_winner(
  p_game_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can finish games';
  END IF;
  
  UPDATE public.games
  SET 
    status = 'completed',
    finished_at = now()
  WHERE id = p_game_id;
END;
$$;

-- Recreate purchase_game_entry with search_path
CREATE FUNCTION public.purchase_game_entry(
  p_game_id uuid,
  p_room_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_entry_cost numeric;
  v_current_balance numeric;
  v_participant_id uuid;
BEGIN
  v_user_id := auth.uid();
  
  SELECT default_entry_cost INTO v_entry_cost
  FROM public.rooms
  WHERE id = p_room_id;
  
  SELECT balance INTO v_current_balance
  FROM public.user_profiles
  WHERE id = v_user_id;
  
  IF v_current_balance < v_entry_cost THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;
  
  UPDATE public.user_profiles
  SET balance = balance - v_entry_cost
  WHERE id = v_user_id;
  
  INSERT INTO public.transactions (user_id, game_id, amount, transaction_type, description)
  VALUES (v_user_id, p_game_id, -v_entry_cost, 'game_entry', 'Game entry purchase');
  
  INSERT INTO public.game_participants (game_id, user_id)
  VALUES (p_game_id, v_user_id)
  RETURNING id INTO v_participant_id;
  
  RETURN v_participant_id;
END;
$$;

-- Recreate claim_prize with search_path
CREATE FUNCTION public.claim_prize(
  p_game_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_prize_pool numeric;
BEGIN
  v_user_id := auth.uid();
  
  SELECT prize_pool INTO v_prize_pool
  FROM public.games
  WHERE id = p_game_id AND winner_id = v_user_id;
  
  IF v_prize_pool IS NULL THEN
    RAISE EXCEPTION 'You are not the winner of this game';
  END IF;
  
  UPDATE public.user_profiles
  SET balance = balance + v_prize_pool
  WHERE id = v_user_id;
  
  INSERT INTO public.transactions (user_id, game_id, amount, transaction_type, description)
  VALUES (v_user_id, p_game_id, v_prize_pool, 'prize', 'Prize winnings');
END;
$$;

-- Recreate admin_add_balance with search_path
CREATE FUNCTION public.admin_add_balance(
  p_user_id uuid,
  p_amount numeric,
  p_description text DEFAULT 'Admin balance adjustment'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can add balance';
  END IF;
  
  UPDATE public.user_profiles
  SET balance = balance + p_amount
  WHERE id = p_user_id;
  
  INSERT INTO public.transactions (user_id, amount, transaction_type, description)
  VALUES (p_user_id, p_amount, 'admin_adjustment', p_description);
END;
$$;

-- Recreate admin_update_profile with search_path
CREATE FUNCTION public.admin_update_profile(
  p_user_id uuid,
  p_role text DEFAULT NULL,
  p_balance numeric DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can update profiles';
  END IF;
  
  IF p_role IS NOT NULL THEN
    UPDATE public.user_profiles
    SET role = p_role
    WHERE id = p_user_id;
  END IF;
  
  IF p_balance IS NOT NULL THEN
    UPDATE public.user_profiles
    SET balance = p_balance
    WHERE id = p_user_id;
  END IF;
END;
$$;