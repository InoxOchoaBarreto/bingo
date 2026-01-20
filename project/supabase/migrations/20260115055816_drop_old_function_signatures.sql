/*
  # Drop Old Function Signatures

  1. Issue
    - Multiple function overloads exist with different signatures
    - Old signatures don't have secure search_path set
    - This creates security vulnerabilities
    
  2. Actions
    - Drop old function signatures that lack search_path protection
    - Keep new versions with proper security configuration
    
  3. Security
    - Removes vulnerable function versions
    - Maintains functionality with secure versions
*/

-- Drop old function signatures without search_path

DROP FUNCTION IF EXISTS public.admin_add_balance(p_admin_id uuid, p_user_id uuid, p_amount numeric);

DROP FUNCTION IF EXISTS public.admin_update_profile(p_admin_id uuid, p_user_id uuid, p_full_name text, p_phone text, p_role text);

DROP FUNCTION IF EXISTS public.claim_prize(p_game_id uuid, p_user_id uuid);

DROP FUNCTION IF EXISTS public.finish_game_with_winner(p_game_id uuid, p_winner_id uuid, p_pattern jsonb);