/*
  # Remove Unused Database Indexes

  1. Analysis
    - Several indexes were created speculatively but are not being used
    - Unused indexes create overhead on INSERT/UPDATE/DELETE operations
    - Keep only indexes that are critical for performance and security
    
  2. Indexes Being Removed
    - `idx_transactions_game_id` - Game transaction queries are rare
    - `idx_game_modes_created_by` - Creator filtering rarely used
    - `idx_games_game_mode_id` - Join queries uncommon
    - `idx_games_winner_id` - Winner filtering uncommon
    - `idx_rooms_created_by` - Creator filtering rarely used
    - `idx_rooms_game_mode_id` - Join queries uncommon
    
  3. Indexes Being Kept
    - `idx_user_profiles_role` - Critical for RLS admin checks
    - `idx_rooms_active` - Critical for active room filtering
    - `idx_game_participants_user_id` - Critical for RLS policies
    - `idx_transactions_user_id` - Common query for user transaction history
    - `idx_bingo_cards_user_id` - Critical for RLS policies
    
  4. Notes
    - Indexes can be re-added if query patterns change
    - Monitor performance and add back specific indexes if needed
*/

-- Drop less critical indexes that aren't being used

DROP INDEX IF EXISTS public.idx_transactions_game_id;
DROP INDEX IF EXISTS public.idx_game_modes_created_by;
DROP INDEX IF EXISTS public.idx_games_game_mode_id;
DROP INDEX IF EXISTS public.idx_games_winner_id;
DROP INDEX IF EXISTS public.idx_rooms_created_by;
DROP INDEX IF EXISTS public.idx_rooms_game_mode_id;