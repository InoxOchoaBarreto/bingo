/*
  # Bingo Multiplayer Game Schema
  
  ## Overview
  Complete database schema for a multiplayer bingo game with multiple rooms,
  authentication, admin panel, and real-time gameplay features.
  
  ## New Tables
  
  ### 1. `user_profiles`
  - `id` (uuid, references auth.users)
  - `full_name` (text)
  - `phone` (text, optional)
  - `role` (text: 'player' or 'admin')
  - `points` (integer, default 0)
  - `wins` (integer, default 0)
  - `games_played` (integer, default 0)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ### 2. `game_modes`
  - `id` (uuid, primary key)
  - `name` (text, e.g., "Bingo Completo", "Línea", "4 Esquinas")
  - `description` (text)
  - `pattern` (jsonb, defines winning pattern)
  - `max_players` (integer)
  - `ball_interval_seconds` (integer, time between ball calls)
  - `active` (boolean)
  - `created_by` (uuid, references user_profiles)
  - `created_at` (timestamptz)
  
  ### 3. `rooms`
  - `id` (uuid, primary key)
  - `name` (text)
  - `game_mode_id` (uuid, references game_modes)
  - `max_players` (integer)
  - `min_players` (integer, default 3)
  - `is_active` (boolean)
  - `created_by` (uuid, references user_profiles)
  - `created_at` (timestamptz)
  
  ### 4. `games`
  - `id` (uuid, primary key)
  - `room_id` (uuid, references rooms)
  - `game_mode_id` (uuid, references game_modes)
  - `status` (text: 'waiting', 'in_progress', 'finished')
  - `started_at` (timestamptz)
  - `finished_at` (timestamptz)
  - `winner_id` (uuid, references user_profiles)
  - `current_ball` (integer)
  - `created_at` (timestamptz)
  
  ### 5. `game_participants`
  - `id` (uuid, primary key)
  - `game_id` (uuid, references games)
  - `user_id` (uuid, references user_profiles)
  - `joined_at` (timestamptz)
  - `is_ready` (boolean)
  
  ### 6. `bingo_cards`
  - `id` (uuid, primary key)
  - `game_id` (uuid, references games)
  - `user_id` (uuid, references user_profiles)
  - `numbers` (jsonb, 5x5 grid of numbers)
  - `marked_numbers` (jsonb, array of marked numbers)
  - `created_at` (timestamptz)
  
  ### 7. `called_numbers`
  - `id` (uuid, primary key)
  - `game_id` (uuid, references games)
  - `number` (integer)
  - `letter` (text: 'B', 'I', 'N', 'G', 'O')
  - `called_at` (timestamptz)
  - `order` (integer)
  
  ## Security
  - Enable RLS on all tables
  - Admin users can manage game modes, rooms, and view all data
  - Players can view active rooms and games they're participating in
  - Players can only modify their own cards and profiles
  - Public can view active rooms (for lobby)
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  phone text,
  role text NOT NULL DEFAULT 'player' CHECK (role IN ('player', 'admin')),
  points integer DEFAULT 0,
  wins integer DEFAULT 0,
  games_played integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create game_modes table
CREATE TABLE IF NOT EXISTS game_modes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  pattern jsonb NOT NULL,
  max_players integer DEFAULT 10,
  ball_interval_seconds integer DEFAULT 5,
  active boolean DEFAULT true,
  created_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE game_modes ENABLE ROW LEVEL SECURITY;

-- Create rooms table
CREATE TABLE IF NOT EXISTS rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  game_mode_id uuid REFERENCES game_modes(id) ON DELETE CASCADE,
  max_players integer DEFAULT 10,
  min_players integer DEFAULT 3,
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Create games table
CREATE TABLE IF NOT EXISTS games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES rooms(id) ON DELETE CASCADE,
  game_mode_id uuid REFERENCES game_modes(id) ON DELETE CASCADE,
  status text DEFAULT 'waiting' CHECK (status IN ('waiting', 'in_progress', 'finished')),
  started_at timestamptz,
  finished_at timestamptz,
  winner_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  current_ball integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Create game_participants table
CREATE TABLE IF NOT EXISTS game_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid REFERENCES games(id) ON DELETE CASCADE,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  is_ready boolean DEFAULT false,
  UNIQUE(game_id, user_id)
);

ALTER TABLE game_participants ENABLE ROW LEVEL SECURITY;

-- Create bingo_cards table
CREATE TABLE IF NOT EXISTS bingo_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid REFERENCES games(id) ON DELETE CASCADE,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  numbers jsonb NOT NULL,
  marked_numbers jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(game_id, user_id)
);

ALTER TABLE bingo_cards ENABLE ROW LEVEL SECURITY;

-- Create called_numbers table
CREATE TABLE IF NOT EXISTS called_numbers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid REFERENCES games(id) ON DELETE CASCADE,
  number integer NOT NULL,
  letter text NOT NULL CHECK (letter IN ('B', 'I', 'N', 'G', 'O')),
  called_at timestamptz DEFAULT now(),
  "order" integer NOT NULL
);

ALTER TABLE called_numbers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- RLS Policies for game_modes
CREATE POLICY "Anyone can view active game modes"
  ON game_modes FOR SELECT
  TO authenticated
  USING (active = true OR created_by = auth.uid() OR 
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can insert game modes"
  ON game_modes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update game modes"
  ON game_modes FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete game modes"
  ON game_modes FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS Policies for rooms
CREATE POLICY "Anyone can view active rooms"
  ON rooms FOR SELECT
  TO authenticated
  USING (is_active = true OR 
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can insert rooms"
  ON rooms FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update rooms"
  ON rooms FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete rooms"
  ON rooms FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS Policies for games
CREATE POLICY "Users can view games they participate in"
  ON games FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM game_participants WHERE game_id = games.id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can insert games"
  ON games FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "System can update games"
  ON games FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM game_participants WHERE game_id = games.id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM game_participants WHERE game_id = games.id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS Policies for game_participants
CREATE POLICY "Users can view participants in their games"
  ON game_participants FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM game_participants gp WHERE gp.game_id = game_participants.game_id AND gp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can join games"
  ON game_participants FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their participation status"
  ON game_participants FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for bingo_cards
CREATE POLICY "Users can view cards in their games"
  ON bingo_cards FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM game_participants WHERE game_id = bingo_cards.game_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can create their own cards"
  ON bingo_cards FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cards"
  ON bingo_cards FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for called_numbers
CREATE POLICY "Users can view called numbers in their games"
  ON called_numbers FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM game_participants WHERE game_id = called_numbers.game_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "System can insert called numbers"
  ON called_numbers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_rooms_active ON rooms(is_active);
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_games_room_id ON games(room_id);
CREATE INDEX IF NOT EXISTS idx_game_participants_game_id ON game_participants(game_id);
CREATE INDEX IF NOT EXISTS idx_game_participants_user_id ON game_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_bingo_cards_game_user ON bingo_cards(game_id, user_id);
CREATE INDEX IF NOT EXISTS idx_called_numbers_game_id ON called_numbers(game_id);

-- Function to update user_profiles.updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();