/*
  # Update Auto Profile Trigger to Include Phone
  
  ## Overview
  Update the trigger function to also extract and store the phone number
  from user metadata.
  
  ## Changes
  1. Drop and recreate the trigger function
  2. Extract both full_name and phone from raw_user_meta_data
  
  ## Security
  - Maintains SECURITY DEFINER privileges
  - Secure search_path remains in place
*/

-- Drop existing function
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Recreate function with phone support
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.raw_user_meta_data->>'phone',
    'player'
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
