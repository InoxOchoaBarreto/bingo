/*
  # Create Automatic User Profile Trigger
  
  ## Overview
  Automatically create a user profile when a new user signs up in auth.users.
  This solves RLS issues by using a SECURITY DEFINER function that runs with
  elevated privileges.
  
  ## Changes
  1. Create trigger function to auto-create user profiles
  2. Add trigger on auth.users to call the function
  3. Handle conflicts gracefully (user profile may already exist)
  
  ## Security
  - Function runs as SECURITY DEFINER to bypass RLS
  - Only creates profile for the newly registered user
  - Uses secure search_path to prevent SQL injection
  
  ## Notes
  - This eliminates the need for manual profile creation in the frontend
  - The trigger runs immediately after user registration
  - Default values are applied automatically (role='player', balance=100.00)
*/

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Create function to handle new user creation
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Insert new user profile
  -- Use INSERT ... ON CONFLICT to handle cases where profile might already exist
  INSERT INTO public.user_profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    'player'
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
