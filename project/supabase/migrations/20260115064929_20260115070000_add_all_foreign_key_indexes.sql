/*
  # Add Foreign Key Indexes

  1. Overview
    - Adding indexes for all foreign key columns to optimize query performance
    - Foreign key indexes improve JOIN operations and CASCADE operations
    - These indexes are essential for database performance and security

  2. New Indexes
    - `idx_bingo_cards_user_id` - For querying bingo cards by user
    - `idx_game_modes_created_by` - For querying game modes by creator
    - `idx_game_participants_user_id` - For querying user participation
    - `idx_games_game_mode_id` - For querying games by mode
    - `idx_games_winner_id` - For querying games by winner
    - `idx_rooms_created_by` - For querying rooms by creator
    - `idx_rooms_game_mode_id` - For querying rooms by game mode
    - `idx_transactions_game_id` - For querying transactions by game
    - `idx_transactions_user_id` - For querying user transaction history

  3. Performance Benefits
    - Faster JOIN operations
    - Improved CASCADE DELETE/UPDATE performance
    - Better query optimization for foreign key filters
    - Reduced query execution time

  4. Security
    - Improves RLS policy evaluation performance
    - Ensures foreign key constraints are checked efficiently
*/

-- Add index on bingo_cards.user_id
CREATE INDEX IF NOT EXISTS idx_bingo_cards_user_id
ON public.bingo_cards(user_id);

-- Add index on game_modes.created_by
CREATE INDEX IF NOT EXISTS idx_game_modes_created_by
ON public.game_modes(created_by);

-- Add index on game_participants.user_id
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id
ON public.game_participants(user_id);

-- Add index on games.game_mode_id
CREATE INDEX IF NOT EXISTS idx_games_game_mode_id
ON public.games(game_mode_id);

-- Add index on games.winner_id
CREATE INDEX IF NOT EXISTS idx_games_winner_id
ON public.games(winner_id);

-- Add index on rooms.created_by
CREATE INDEX IF NOT EXISTS idx_rooms_created_by
ON public.rooms(created_by);

-- Add index on rooms.game_mode_id
CREATE INDEX IF NOT EXISTS idx_rooms_game_mode_id
ON public.rooms(game_mode_id);

-- Add index on transactions.game_id
CREATE INDEX IF NOT EXISTS idx_transactions_game_id
ON public.transactions(game_id);

-- Add index on transactions.user_id
CREATE INDEX IF NOT EXISTS idx_transactions_user_id
ON public.transactions(user_id);
