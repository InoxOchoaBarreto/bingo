/*
  # Add Default Entry Cost to Rooms
  
  1. Changes
    - Add `default_entry_cost` column to rooms table
    - This will be used when creating new games in the room
  
  2. Notes
    - Default value is 10.00
    - Can be customized by admins when creating/editing rooms
*/

-- Add default_entry_cost to rooms
ALTER TABLE rooms 
ADD COLUMN IF NOT EXISTS default_entry_cost NUMERIC(10, 2) DEFAULT 10.00 NOT NULL;