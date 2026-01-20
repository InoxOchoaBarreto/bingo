/*
  # Add Missing Foreign Key Indexes

  This migration adds indexes for all foreign keys that were missing covering indexes,
  which improves query performance when joining tables or filtering by foreign keys.

  ## New Indexes
  
  1. **bingo_cards**
    - `idx_bingo_cards_user_id` on `user_id` column
  
  2. **game_modes**
    - `idx_game_modes_created_by` on `created_by` column
  
  3. **game_participants**
    - `idx_game_participants_user_id` on `user_id` column
  
  4. **games**
    - `idx_games_game_mode_id` on `game_mode_id` column
    - `idx_games_winner_id` on `winner_id` column
  
  5. **rooms**
    - `idx_rooms_created_by` on `created_by` column
    - `idx_rooms_game_mode_id` on `game_mode_id` column
  
  6. **transactions**
    - `idx_transactions_game_id` on `game_id` column
    - `idx_transactions_user_id` on `user_id` column

  ## Performance Impact
  
  These indexes will significantly improve:
  - JOIN operations between tables
  - Filtering queries by foreign key columns
  - Foreign key constraint validation performance
*/

-- Add index for bingo_cards.user_id
CREATE INDEX IF NOT EXISTS idx_bingo_cards_user_id ON bingo_cards(user_id);

-- Add index for game_modes.created_by
CREATE INDEX IF NOT EXISTS idx_game_modes_created_by ON game_modes(created_by);

-- Add index for game_participants.user_id
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id ON game_participants(user_id);

-- Add index for games.game_mode_id
CREATE INDEX IF NOT EXISTS idx_games_game_mode_id ON games(game_mode_id);

-- Add index for games.winner_id
CREATE INDEX IF NOT EXISTS idx_games_winner_id ON games(winner_id);

-- Add index for rooms.created_by
CREATE INDEX IF NOT EXISTS idx_rooms_created_by ON rooms(created_by);

-- Add index for rooms.game_mode_id
CREATE INDEX IF NOT EXISTS idx_rooms_game_mode_id ON rooms(game_mode_id);

-- Add index for transactions.game_id
CREATE INDEX IF NOT EXISTS idx_transactions_game_id ON transactions(game_id);

-- Add index for transactions.user_id
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);