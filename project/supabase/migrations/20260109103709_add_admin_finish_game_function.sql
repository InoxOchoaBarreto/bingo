/*
  # Add Admin Game Finish Functions
  
  1. New Functions
    - `admin_finish_game_with_winner`: Admin finishes game declaring a winner
    - `admin_finish_game_no_winner`: Admin cancels/finishes game without winner
  
  2. Security
    - Only admins can call these functions
    - Updates all participant stats appropriately
*/

-- Function for admin to finish game with winner
CREATE OR REPLACE FUNCTION admin_finish_game_with_winner(
  p_game_id uuid,
  p_winner_id uuid
) RETURNS void AS $$
DECLARE
  v_participant RECORD;
BEGIN
  -- Verify the caller is an admin
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized - admin only';
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

-- Function for admin to finish game without winner
CREATE OR REPLACE FUNCTION admin_finish_game_no_winner(
  p_game_id uuid
) RETURNS void AS $$
DECLARE
  v_participant RECORD;
BEGIN
  -- Verify the caller is an admin
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized - admin only';
  END IF;

  -- Update game status
  UPDATE games 
  SET 
    status = 'finished',
    finished_at = now()
  WHERE id = p_game_id;

  -- Update all participants' games_played
  FOR v_participant IN 
    SELECT user_id 
    FROM game_participants 
    WHERE game_id = p_game_id
  LOOP
    UPDATE user_profiles
    SET games_played = games_played + 1
    WHERE id = v_participant.user_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION admin_finish_game_with_winner TO authenticated;
GRANT EXECUTE ON FUNCTION admin_finish_game_no_winner TO authenticated;