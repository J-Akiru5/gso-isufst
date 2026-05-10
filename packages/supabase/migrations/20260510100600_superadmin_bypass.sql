-- Bypass Approval Script for Superadmin
-- This script ensures the superadmin is approved and has the correct role.

DO $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
BEGIN
    -- 1. Get the user ID for the superadmin
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'cictstudentcouncil@isufst.edu.ph';
    
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;

    -- 2. Force approve in profiles
    UPDATE public.profiles 
    SET is_approved = true, 
        is_active = true,
        updated_at = NOW()
    WHERE id = v_user_id;

    -- 3. Get super_admin role ID
    SELECT id INTO v_role_id FROM public.roles WHERE name = 'super_admin';

    -- 4. Ensure user has the role
    IF v_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (v_user_id, v_role_id)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
