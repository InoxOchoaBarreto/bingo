/*
  # Remove Unused Indexes

  Removes database indexes that have not been used, improving database maintenance overhead.

  ## Changes
  
  1. Dropped Indexes
    - `idx_transactions_user_id` - Unused index on transactions.user_id
    - `idx_bingo_cards_user_id` - Unused index on bingo_cards.user_id
    - `idx_game_modes_created_by` - Unused index on game_modes.created_by
    - `idx_game_participants_user_id` - Unused index on game_participants.user_id
    - `idx_games_game_mode_id` - Unused index on games.game_mode_id
    - `idx_games_winner_id` - Unused index on games.winner_id
    - `idx_rooms_created_by` - Unused index on rooms.created_by
    - `idx_rooms_game_mode_id` - Unused index on rooms.game_mode_id
    - `idx_transactions_game_id` - Unused index on transactions.game_id

  ## Notes
  
  - Unused indexes consume storage and slow down write operations without providing query benefits
  - Foreign key constraints already provide necessary referential integrity
  - Indexes can be recreated if usage patterns change
*/

-- Drop unused indexes to reduce maintenance overhead
DROP INDEX IF EXISTS idx_transactions_user_id;
DROP INDEX IF EXISTS idx_bingo_cards_user_id;
DROP INDEX IF EXISTS idx_game_modes_created_by;
DROP INDEX IF EXISTS idx_game_participants_user_id;
DROP INDEX IF EXISTS idx_games_game_mode_id;
DROP INDEX IF EXISTS idx_games_winner_id;
DROP INDEX IF EXISTS idx_rooms_created_by;
DROP INDEX IF EXISTS idx_rooms_game_mode_id;
DROP INDEX IF EXISTS idx_transactions_game_id;