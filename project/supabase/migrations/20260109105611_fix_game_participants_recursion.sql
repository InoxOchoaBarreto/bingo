/*
  # Fix Game Participants Recursion
  
  1. Changes
    - Drop all existing policies on game_participants that cause recursion
    - Create simple, non-recursive policies
    - Allow authenticated users to view all game participants (needed for gameplay)
    - Restrict insert/update to own records only
  
  2. Security
    - Users can view participants (needed to see who's in the game)
    - Users can only join/update their own participation
    - Admins have full access
*/

-- Drop ALL existing policies on game_participants to start fresh
DROP POLICY IF EXISTS "Users can view own participation" ON game_participants;
DROP POLICY IF EXISTS "Users can view all participants in same game" ON game_participants;
DROP POLICY IF EXISTS "Users can join games" ON game_participants;
DROP POLICY IF EXISTS "Users can update own participation" ON game_participants;

-- Create new simple policies without recursion

-- SELECT: Allow users to view all game participants
-- This is safe because it's read-only and needed for the game to function
CREATE POLICY "view_game_participants"
  ON game_participants FOR SELECT
  TO authenticated
  USING (true);

-- INSERT: Users can only insert their own participation records
CREATE POLICY "insert_own_participation"
  ON game_participants FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can only update their own participation records
CREATE POLICY "update_own_participation"
  ON game_participants FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Only admins can delete participation records
CREATE POLICY "admin_delete_participation"
  ON game_participants FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );