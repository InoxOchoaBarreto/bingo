/*
  # Add Indexes for Foreign Keys

  1. Overview
    - Adding indexes for all foreign key columns to optimize JOIN operations and CASCADE operations
    - Foreign key indexes are essential for database performance
    
  2. New Indexes
    - `idx_bingo_cards_user_id` - For querying all cards by user
    - `idx_game_modes_created_by` - For admin queries on game mode creators
    - `idx_game_participants_user_id` - For querying all games a user participated in
    - `idx_games_game_mode_id` - For querying all games by mode
    - `idx_games_winner_id` - For querying games won by a user
    - `idx_rooms_created_by` - For querying rooms created by a user
    - `idx_rooms_game_mode_id` - For querying rooms by game mode
    - `idx_transactions_game_id` - For querying all transactions for a game
    
  3. Performance Benefits
    - Faster JOIN operations when referencing these tables
    - Improved CASCADE DELETE/UPDATE performance
    - Better query optimization for filters on foreign key columns
    
  4. Notes
    - These indexes complement existing composite indexes
    - idx_transactions_user_id already exists and is kept for user balance queries
    - All foreign keys should have indexes unless there's a specific reason not to
*/

-- Add index on bingo_cards.user_id for user-based queries
CREATE INDEX IF NOT EXISTS idx_bingo_cards_user_id 
ON public.bingo_cards(user_id);

-- Add index on game_modes.created_by for admin queries
CREATE INDEX IF NOT EXISTS idx_game_modes_created_by 
ON public.game_modes(created_by);

-- Add index on game_participants.user_id for user participation queries
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id 
ON public.game_participants(user_id);

-- Add index on games.game_mode_id for game mode queries
CREATE INDEX IF NOT EXISTS idx_games_game_mode_id 
ON public.games(game_mode_id);

-- Add index on games.winner_id for winner queries
CREATE INDEX IF NOT EXISTS idx_games_winner_id 
ON public.games(winner_id);

-- Add index on rooms.created_by for room creator queries
CREATE INDEX IF NOT EXISTS idx_rooms_created_by 
ON public.rooms(created_by);

-- Add index on rooms.game_mode_id for room game mode queries
CREATE INDEX IF NOT EXISTS idx_rooms_game_mode_id 
ON public.rooms(game_mode_id);

-- Add index on transactions.game_id for game transaction queries
CREATE INDEX IF NOT EXISTS idx_transactions_game_id 
ON public.transactions(game_id);