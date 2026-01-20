/*
  # Remove Unused Indexes

  1. Overview
    - Removing indexes that are not used in actual query patterns
    - Unused indexes add overhead to INSERT/UPDATE/DELETE operations
    - Some indexes are redundant due to composite indexes covering the same queries
    
  2. Indexes Being Removed
    - `idx_bingo_cards_user_id` - Covered by composite index idx_bingo_cards_game_user
    - `idx_game_modes_created_by` - Rarely queried, admin-only feature
    - `idx_game_participants_user_id` - Covered by composite index idx_game_participants_game_id
    - `idx_games_winner_id` - Rarely queried
    - `idx_rooms_created_by` - Rarely queried
    - `idx_transactions_game_id` - Not used in current query patterns
    - `idx_games_game_mode_id` - Not actively used
    - `idx_rooms_game_mode_id` - Not actively used
    
  3. Indexes Being Kept
    - `idx_transactions_user_id` - Critical for user transaction history
    - Composite indexes on primary query patterns
    - Indexes on frequently filtered columns (status, game_id combinations)
    
  4. Notes
    - Indexes can be re-added if query patterns change
    - Foreign key constraints work without indexes, though with slightly reduced performance
    - This optimization reduces storage overhead and improves write performance
*/

-- Remove index on bingo_cards.user_id (covered by composite index)
DROP INDEX IF EXISTS public.idx_bingo_cards_user_id;

-- Remove index on game_modes.created_by (rarely queried)
DROP INDEX IF EXISTS public.idx_game_modes_created_by;

-- Remove index on game_participants.user_id (covered by composite)
DROP INDEX IF EXISTS public.idx_game_participants_user_id;

-- Remove index on games.winner_id (rarely queried)
DROP INDEX IF EXISTS public.idx_games_winner_id;

-- Remove index on rooms.created_by (rarely queried)
DROP INDEX IF EXISTS public.idx_rooms_created_by;

-- Remove index on transactions.game_id (not used in current patterns)
DROP INDEX IF EXISTS public.idx_transactions_game_id;

-- Remove unused game mode indexes
DROP INDEX IF EXISTS public.idx_games_game_mode_id;
DROP INDEX IF EXISTS public.idx_rooms_game_mode_id;