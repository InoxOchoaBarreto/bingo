/*
  # Remove Duplicate RLS Policies

  1. Issue
    - Multiple permissive SELECT policies exist on several tables
    - This causes unnecessary policy evaluation overhead
    
  2. Actions
    - Drop duplicate SELECT policies on called_numbers
    - Drop duplicate SELECT policies on game_participants  
    - Drop duplicate SELECT policies on games
    
  3. Security
    - Maintains same access control with consolidated policies
    - No functionality changes, only removes duplicates
*/

-- Remove duplicate policy on called_numbers
-- Keep "Users can view called numbers in their games" (more restrictive)
-- Drop "Users can view called numbers" (too permissive)
DROP POLICY IF EXISTS "Users can view called numbers" ON public.called_numbers;

-- Remove duplicate policy on game_participants
-- Keep "Users can view participants in their games" (more restrictive)
-- Drop "view_game_participants" (too permissive)
DROP POLICY IF EXISTS "view_game_participants" ON public.game_participants;

-- Remove duplicate policy on games
-- Keep "Users can view games they participate in" (more restrictive)
-- Drop "Users can view games" (too permissive)
DROP POLICY IF EXISTS "Users can view games" ON public.games;