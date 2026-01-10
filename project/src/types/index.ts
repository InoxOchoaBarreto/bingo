export interface UserProfile {
  id: string;
  full_name: string;
  phone: string | null;
  role: 'player' | 'admin';
  points: number;
  wins: number;
  games_played: number;
  balance: number;
  created_at: string;
  updated_at: string;
}

export interface GameMode {
  id: string;
  name: string;
  description: string | null;
  pattern: {
    type: 'horizontal_line' | 'vertical_line' | 'diagonal' | 'four_corners' | 'full_card' | 'x_pattern';
  };
  max_players: number;
  ball_interval_seconds: number;
  active: boolean;
  created_by: string | null;
  created_at: string;
}

export interface Room {
  id: string;
  name: string;
  game_mode_id: string;
  max_players: number;
  min_players: number;
  is_active: boolean;
  default_entry_cost: number;
  created_by: string | null;
  created_at: string;
  game_mode?: GameMode;
}

export interface Game {
  id: string;
  room_id: string;
  game_mode_id: string;
  status: 'waiting' | 'in_progress' | 'finished';
  started_at: string | null;
  finished_at: string | null;
  winner_id: string | null;
  current_ball: number;
  entry_cost: number;
  prize_pool: number;
  created_at: string;
}

export interface GameParticipant {
  id: string;
  game_id: string;
  user_id: string;
  joined_at: string;
  is_ready: boolean;
  paid_entry: boolean;
  user_profile?: UserProfile;
}

export interface Transaction {
  id: string;
  user_id: string;
  game_id: string | null;
  type: 'deposit' | 'entry_fee' | 'prize_win' | 'refund';
  amount: number;
  balance_after: number;
  description: string | null;
  created_at: string;
}

export interface BingoCard {
  id: string;
  game_id: string;
  user_id: string;
  numbers: number[][];
  marked_numbers: number[];
  created_at: string;
}

export interface CalledNumber {
  id: string;
  game_id: string;
  number: number;
  letter: 'B' | 'I' | 'N' | 'G' | 'O';
  called_at: string;
  order: number;
}
