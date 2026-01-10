/*
  # Allow Users to Create Games
  
  1. Changes
    - Update the INSERT policy on games table to allow authenticated users to create games in "waiting" status
    - This allows players to join rooms and automatically create games when needed
    - Admins retain full control over game lifecycle
  
  2. Security
    - Users can only create games in "waiting" status
    - Game control (starting, finishing) remains admin-only through the admin panel
*/

-- Drop the existing insert policy
DROP POLICY IF EXISTS "Admins can insert games" ON games;

-- Create new policy that allows authenticated users to create games
CREATE POLICY "Users can create games"
  ON games FOR INSERT
  TO authenticated
  WITH CHECK (
    status = 'waiting' OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );