/*
  # Admin Balance Management Functions
  
  1. New Functions
    - `admin_add_balance` - Allows admins to add balance to user accounts
    - `admin_update_profile` - Allows admins to update user profiles
  
  2. Security
    - Functions check if the caller is an admin
    - All transactions are recorded
    - Balance changes are atomic
*/

-- Function for admins to add balance to users
CREATE OR REPLACE FUNCTION admin_add_balance(
  p_admin_id UUID,
  p_user_id UUID,
  p_amount NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_admin_role TEXT;
  v_current_balance NUMERIC;
  v_new_balance NUMERIC;
BEGIN
  -- Check if caller is admin
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;
  
  IF v_admin_role IS NULL OR v_admin_role != 'admin' THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized: Admin access required');
  END IF;
  
  -- Validate amount
  IF p_amount <= 0 THEN
    RETURN json_build_object('success', false, 'error', 'Amount must be positive');
  END IF;
  
  -- Get current balance
  SELECT balance INTO v_current_balance
  FROM user_profiles
  WHERE id = p_user_id;
  
  IF v_current_balance IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;
  
  -- Calculate new balance
  v_new_balance := v_current_balance + p_amount;
  
  -- Update user balance
  UPDATE user_profiles
  SET balance = v_new_balance
  WHERE id = p_user_id;
  
  -- Record transaction
  INSERT INTO transactions (user_id, type, amount, balance_after, description)
  VALUES (
    p_user_id,
    'deposit',
    p_amount,
    v_new_balance,
    'Balance added by admin'
  );
  
  RETURN json_build_object(
    'success', true,
    'new_balance', v_new_balance,
    'amount_added', p_amount
  );
END;
$$;

-- Function for admins to update user profiles
CREATE OR REPLACE FUNCTION admin_update_profile(
  p_admin_id UUID,
  p_user_id UUID,
  p_full_name TEXT,
  p_phone TEXT,
  p_role TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_admin_role TEXT;
BEGIN
  -- Check if caller is admin
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;
  
  IF v_admin_role IS NULL OR v_admin_role != 'admin' THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized: Admin access required');
  END IF;
  
  -- Validate role
  IF p_role NOT IN ('player', 'admin') THEN
    RETURN json_build_object('success', false, 'error', 'Invalid role');
  END IF;
  
  -- Update profile
  UPDATE user_profiles
  SET 
    full_name = p_full_name,
    phone = p_phone,
    role = p_role,
    updated_at = now()
  WHERE id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;
  
  RETURN json_build_object('success', true);
END;
$$;