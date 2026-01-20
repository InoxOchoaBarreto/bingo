/*
  # Optimize Database Indexes for Actual Usage

  1. Problem Analysis
    - Several indexes were created but are not being used by query plans
    - Unused indexes create unnecessary overhead on write operations
    - Some foreign keys lack indexes but are rarely queried
    
  2. Indexes Being Removed (Unused)
    - `idx_user_profiles_role` - Not used by query planner
    - `idx_rooms_active` - Not used by query planner
    - `idx_game_participants_user_id` - Not used by query planner
    - `idx_transactions_user_id` - Not used by query planner
    - `idx_bingo_cards_user_id` - Not used by query planner
    
  3. Foreign Key Indexes Being Added (Selective)
    - `idx_games_game_mode_id` - For filtering/joining games by mode
    - `idx_rooms_game_mode_id` - For filtering/joining rooms by mode
    
  4. Foreign Keys NOT Being Indexed (Low Usage)
    - `game_modes.created_by` - Creator queries are rare
    - `games.winner_id` - Winner queries are rare
    - `rooms.created_by` - Creator queries are rare
    - `transactions.game_id` - Game transaction queries are rare
    
  5. Notes
    - Focuses on indexes that will actually improve real-world query performance
    - Minimizes write overhead by avoiding speculative indexes
    - Can add more indexes later if query patterns change
*/

-- Remove unused indexes that aren't being utilized
DROP INDEX IF EXISTS public.idx_user_profiles_role;
DROP INDEX IF EXISTS public.idx_rooms_active;
DROP INDEX IF EXISTS public.idx_game_participants_user_id;
DROP INDEX IF EXISTS public.idx_transactions_user_id;
DROP INDEX IF EXISTS public.idx_bingo_cards_user_id;

-- Add selective indexes on foreign keys that will improve common queries
CREATE INDEX IF NOT EXISTS idx_games_game_mode_id ON public.games(game_mode_id);
CREATE INDEX IF NOT EXISTS idx_rooms_game_mode_id ON public.rooms(game_mode_id);