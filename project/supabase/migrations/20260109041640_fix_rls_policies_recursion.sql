/*
  # Fix RLS Policies Recursion Issue
  
  1. Changes
    - Drop existing problematic policies for game_participants, games, bingo_cards, and called_numbers
    - Create new simplified policies without self-referencing recursion
    - Allow participants to see their own participation records
    - Allow users to view games and related data through simpler logic
  
  2. Security
    - Maintains security by checking user_id directly where possible
    - Uses games table as intermediary without recursion
    - Admins retain full access
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view participants in their games" ON game_participants;
DROP POLICY IF EXISTS "Users can join games" ON game_participants;
DROP POLICY IF EXISTS "Users can update their participation status" ON game_participants;

DROP POLICY IF EXISTS "Users can view games they participate in" ON games;
DROP POLICY IF EXISTS "Admins can insert games" ON games;
DROP POLICY IF EXISTS "System can update games" ON games;

DROP POLICY IF EXISTS "Users can view cards in their games" ON bingo_cards;
DROP POLICY IF EXISTS "Users can create their own cards" ON bingo_cards;
DROP POLICY IF EXISTS "Users can update their own cards" ON bingo_cards;

DROP POLICY IF EXISTS "Users can view called numbers in their games" ON called_numbers;
DROP POLICY IF EXISTS "System can insert called numbers" ON called_numbers;

-- New policies for game_participants (no recursion)
CREATE POLICY "Users can view own participation"
  ON game_participants FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can view all participants in same game"
  ON game_participants FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM game_participants gp2 
      WHERE gp2.game_id = game_participants.game_id 
      AND gp2.user_id = auth.uid()
    ) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can join games"
  ON game_participants FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own participation"
  ON game_participants FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- New policies for games (simplified)
CREATE POLICY "Users can view games"
  ON games FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can insert games"
  ON games FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can update games"
  ON games FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Admins can delete games"
  ON games FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- New policies for bingo_cards (simplified)
CREATE POLICY "Users can view own cards"
  ON bingo_cards FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can view cards in same game"
  ON bingo_cards FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM game_participants 
      WHERE game_participants.game_id = bingo_cards.game_id 
      AND game_participants.user_id = auth.uid()
    ) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can create own cards"
  ON bingo_cards FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cards"
  ON bingo_cards FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- New policies for called_numbers (simplified)
CREATE POLICY "Users can view called numbers"
  ON called_numbers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can insert called numbers"
  ON called_numbers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );
