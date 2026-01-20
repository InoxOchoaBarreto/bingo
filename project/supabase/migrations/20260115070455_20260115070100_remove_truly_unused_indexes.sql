/*
  # Remove Unused Foreign Key Indexes

  1. Analysis
    - Reviewed all application queries to identify which indexes are actually used
    - Found that several foreign key indexes were added but are never used by queries
    - Keeping indexes that aren't used creates unnecessary write overhead
    
  2. Query Pattern Analysis
    - bingo_cards: Always queries by (game_id, user_id) together - covered by composite index
    - game_participants: Always queries by (game_id, user_id) together - covered by composite index
    - game_modes: Never queries by created_by
    - games: Never queries by game_mode_id or winner_id (only uses JOINs, not filters)
    - rooms: Never queries by created_by or game_mode_id (only uses JOINs, not filters)
    - transactions: No queries on transactions table at all
    
  3. Indexes Being Removed (Confirmed Unused)
    - `idx_bingo_cards_user_id` - Redundant with composite index idx_bingo_cards_game_user
    - `idx_game_participants_user_id` - Redundant with composite index on (game_id, user_id)
    - `idx_game_modes_created_by` - No queries filter by created_by
    - `idx_games_game_mode_id` - No queries filter by game_mode_id
    - `idx_games_winner_id` - No queries filter by winner_id
    - `idx_rooms_created_by` - No queries filter by created_by
    - `idx_rooms_game_mode_id` - No queries filter by game_mode_id
    - `idx_transactions_game_id` - No transactions queries in application
    - `idx_transactions_user_id` - No transactions queries in application
    
  4. Composite Indexes (Kept)
    - `idx_bingo_cards_game_user` on (game_id, user_id) - Used by actual queries
    - Composite index on game_participants(game_id, user_id) via UNIQUE constraint
    
  5. Performance Impact
    - Reduces write overhead on INSERT/UPDATE/DELETE operations
    - Maintains query performance via composite indexes
    - Can add specific indexes later if query patterns change
*/

-- Remove redundant and unused indexes
DROP INDEX IF EXISTS public.idx_bingo_cards_user_id;
DROP INDEX IF EXISTS public.idx_game_modes_created_by;
DROP INDEX IF EXISTS public.idx_game_participants_user_id;
DROP INDEX IF EXISTS public.idx_games_game_mode_id;
DROP INDEX IF EXISTS public.idx_games_winner_id;
DROP INDEX IF EXISTS public.idx_rooms_created_by;
DROP INDEX IF EXISTS public.idx_rooms_game_mode_id;
DROP INDEX IF EXISTS public.idx_transactions_game_id;
DROP INDEX IF EXISTS public.idx_transactions_user_id;
