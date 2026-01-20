/*
  # Add Missing Foreign Key Indexes

  1. Overview
    - Adding indexes on all foreign keys to ensure optimal query performance
    - Foreign keys without indexes can cause performance issues during JOINs and cascading operations
    
  2. Indexes Being Added
    - `idx_bingo_cards_user_id` - For finding all bingo cards by user
    - `idx_game_modes_created_by` - For finding game modes created by user
    - `idx_game_participants_user_id` - For finding all games a user participated in
    - `idx_games_winner_id` - For finding games won by a specific user
    - `idx_rooms_created_by` - For finding rooms created by user
    - `idx_transactions_game_id` - For finding all transactions for a game
    - `idx_transactions_user_id` - For finding user's transaction history
    
  3. Notes
    - Some queries may already be covered by composite indexes, but single-column indexes
      ensure optimal performance for all query patterns
    - Foreign key indexes are especially important for DELETE operations to check referential integrity
*/

-- Add index on bingo_cards.user_id for user-specific card queries
CREATE INDEX IF NOT EXISTS idx_bingo_cards_user_id ON public.bingo_cards(user_id);

-- Add index on game_modes.created_by for creator lookups
CREATE INDEX IF NOT EXISTS idx_game_modes_created_by ON public.game_modes(created_by);

-- Add index on game_participants.user_id for user participation queries
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id ON public.game_participants(user_id);

-- Add index on games.winner_id for winner lookups
CREATE INDEX IF NOT EXISTS idx_games_winner_id ON public.games(winner_id);

-- Add index on rooms.created_by for room creator lookups
CREATE INDEX IF NOT EXISTS idx_rooms_created_by ON public.rooms(created_by);

-- Add index on transactions.game_id for game transaction queries
CREATE INDEX IF NOT EXISTS idx_transactions_game_id ON public.transactions(game_id);

-- Add index on transactions.user_id for user transaction history
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);