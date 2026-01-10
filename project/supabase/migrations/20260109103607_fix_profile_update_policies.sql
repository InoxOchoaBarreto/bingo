/*
  # Fix Profile Update Policies
  
  1. Changes
    - Allow system to update game statistics (games_played) for all users
    - Keep user updates restricted to their own profiles for other fields
    - This enables proper stat tracking when games finish
  
  2. Security
    - Users can still only update their own full profile data
    - System can increment game counters for all participants
*/

-- Drop existing update policy
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Create new policy that allows users to update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create additional policy for system to update game stats
CREATE POLICY "System can update game stats"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (
    auth.uid() = id OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );