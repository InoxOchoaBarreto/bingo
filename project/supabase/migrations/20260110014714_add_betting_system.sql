/*
  # Add Betting System
  
  1. New Fields
    - `user_profiles.balance` (numeric) - User's credit balance
    - `games.entry_cost` (numeric) - Cost to buy a bingo card
    - `games.prize_pool` (numeric) - Accumulated prize money
    - `game_participants.paid_entry` (boolean) - Whether user paid for entry
  
  2. New Tables
    - `transactions` - Track all financial transactions
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to user_profiles)
      - `game_id` (uuid, foreign key to games, nullable)
      - `type` (text) - deposit, entry_fee, prize_win, refund
      - `amount` (numeric)
      - `balance_after` (numeric)
      - `description` (text)
      - `created_at` (timestamptz)
  
  3. Security
    - Enable RLS on transactions table
    - Users can view their own transactions
    - Only system functions can insert transactions
  
  4. Functions
    - `purchase_game_entry` - Buy entry to a game
    - `claim_prize` - Claim prize after winning
*/

-- Add balance to user profiles
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS balance NUMERIC(10, 2) DEFAULT 100.00 NOT NULL;

-- Add betting fields to games
ALTER TABLE games 
ADD COLUMN IF NOT EXISTS entry_cost NUMERIC(10, 2) DEFAULT 10.00 NOT NULL,
ADD COLUMN IF NOT EXISTS prize_pool NUMERIC(10, 2) DEFAULT 0.00 NOT NULL;

-- Add paid_entry to game_participants
ALTER TABLE game_participants 
ADD COLUMN IF NOT EXISTS paid_entry BOOLEAN DEFAULT false NOT NULL;

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  game_id UUID REFERENCES games(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('deposit', 'entry_fee', 'prize_win', 'refund')),
  amount NUMERIC(10, 2) NOT NULL,
  balance_after NUMERIC(10, 2) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS on transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Users can view their own transactions
CREATE POLICY "view_own_transactions"
  ON transactions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_game_id ON transactions(game_id);

-- Function to purchase game entry
CREATE OR REPLACE FUNCTION purchase_game_entry(
  p_game_id UUID,
  p_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_entry_cost NUMERIC;
  v_user_balance NUMERIC;
  v_new_balance NUMERIC;
  v_participant_exists BOOLEAN;
  v_already_paid BOOLEAN;
BEGIN
  -- Get game entry cost
  SELECT entry_cost INTO v_entry_cost
  FROM games
  WHERE id = p_game_id;
  
  IF v_entry_cost IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Game not found');
  END IF;
  
  -- Get user balance
  SELECT balance INTO v_user_balance
  FROM user_profiles
  WHERE id = p_user_id;
  
  -- Check if user has enough balance
  IF v_user_balance < v_entry_cost THEN
    RETURN json_build_object('success', false, 'error', 'Insufficient balance');
  END IF;
  
  -- Check if user is already a participant
  SELECT EXISTS(
    SELECT 1 FROM game_participants 
    WHERE game_id = p_game_id AND user_id = p_user_id
  ) INTO v_participant_exists;
  
  IF v_participant_exists THEN
    -- Check if already paid
    SELECT paid_entry INTO v_already_paid
    FROM game_participants
    WHERE game_id = p_game_id AND user_id = p_user_id;
    
    IF v_already_paid THEN
      RETURN json_build_object('success', false, 'error', 'Already purchased entry');
    END IF;
  END IF;
  
  -- Calculate new balance
  v_new_balance := v_user_balance - v_entry_cost;
  
  -- Update user balance
  UPDATE user_profiles
  SET balance = v_new_balance
  WHERE id = p_user_id;
  
  -- Update game prize pool
  UPDATE games
  SET prize_pool = prize_pool + v_entry_cost
  WHERE id = p_game_id;
  
  -- Insert or update participant record
  IF v_participant_exists THEN
    UPDATE game_participants
    SET paid_entry = true
    WHERE game_id = p_game_id AND user_id = p_user_id;
  ELSE
    INSERT INTO game_participants (game_id, user_id, paid_entry)
    VALUES (p_game_id, p_user_id, true);
  END IF;
  
  -- Record transaction
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

-- Function to claim prize
CREATE OR REPLACE FUNCTION claim_prize(
  p_game_id UUID,
  p_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_prize_pool NUMERIC;
  v_user_balance NUMERIC;
  v_new_balance NUMERIC;
  v_game_status TEXT;
  v_winner_id UUID;
BEGIN
  -- Get game info
  SELECT status, winner_id, prize_pool INTO v_game_status, v_winner_id, v_prize_pool
  FROM games
  WHERE id = p_game_id;
  
  IF v_game_status IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Game not found');
  END IF;
  
  -- Check if game is finished
  IF v_game_status != 'finished' THEN
    RETURN json_build_object('success', false, 'error', 'Game not finished yet');
  END IF;
  
  -- Check if user is the winner
  IF v_winner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'error', 'You are not the winner');
  END IF;
  
  -- Check if prize already claimed
  IF v_prize_pool <= 0 THEN
    RETURN json_build_object('success', false, 'error', 'Prize already claimed');
  END IF;
  
  -- Get user balance
  SELECT balance INTO v_user_balance
  FROM user_profiles
  WHERE id = p_user_id;
  
  -- Calculate new balance
  v_new_balance := v_user_balance + v_prize_pool;
  
  -- Update user balance
  UPDATE user_profiles
  SET balance = v_new_balance
  WHERE id = p_user_id;
  
  -- Clear prize pool
  UPDATE games
  SET prize_pool = 0
  WHERE id = p_game_id;
  
  -- Record transaction
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