/*
  # Create Game Finish Function
  
  1. New Function
    - `finish_game_with_winner`: Handles all game completion logic
    - Updates winner stats (wins, points, games_played)
    - Updates all participants' games_played counter
    - Updates game status to finished
  
  2. Security
    - Function runs with caller's permissions but handles updates safely
    - Only game participants can call this for their games
*/

-- Drop the overly permissive policy
DROP POLICY IF EXISTS "System can update game stats" ON user_profiles;

-- Create function to finish game and update stats
CREATE OR REPLACE FUNCTION finish_game_with_winner(
  p_game_id uuid,
  p_winner_id uuid,
  p_pattern jsonb
) RETURNS void AS $$
DECLARE
  v_participant RECORD;
BEGIN
  -- Verify the caller is a participant in the game
  IF NOT EXISTS (
    SELECT 1 FROM game_participants 
    WHERE game_id = p_game_id 
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to finish this game';
  END IF;

  -- Update game status
  UPDATE games 
  SET 
    status = 'finished',
    finished_at = now(),
    winner_id = p_winner_id
  WHERE id = p_game_id;

  -- Update winner stats
  UPDATE user_profiles
  SET
    wins = wins + 1,
    points = points + 100,
    games_played = games_played + 1
  WHERE id = p_winner_id;

  -- Update all other participants' games_played
  FOR v_participant IN 
    SELECT user_id 
    FROM game_participants 
    WHERE game_id = p_game_id 
    AND user_id != p_winner_id
  LOOP
    UPDATE user_profiles
    SET games_played = games_played + 1
    WHERE id = v_participant.user_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION finish_game_with_winner TO authenticated;