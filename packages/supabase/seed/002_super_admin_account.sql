-- ============================================================
-- Seed Data: Super Admin Account
-- Run AFTER 001_seed.sql and all 001–006 migrations
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
DECLARE
  super_admin_user_id UUID;
  super_admin_role_id UUID;
  user_exists BOOLEAN := FALSE;
BEGIN
  SELECT id
    INTO super_admin_user_id
    FROM auth.users
    WHERE email = 'cictstudentcouncil@isufst.edu.ph';

  IF super_admin_user_id IS NULL THEN
    super_admin_user_id := uuid_generate_v4();
    user_exists := FALSE;
  ELSE
    user_exists := TRUE;
  END IF;

  IF NOT user_exists THEN
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      raw_app_meta_data,
      raw_user_meta_data,
      email_confirmed_at,
      -- GoTrue's Go scanner requires empty strings, not NULL, for these token columns
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change_token_current,
      email_change,
      phone_change,
      phone_change_token,
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      super_admin_user_id,
      'authenticated',
      'authenticated',
      'cictstudentcouncil@isufst.edu.ph',
      crypt('Gso_Admin_2026', gen_salt('bf')),
      '{"provider": "email", "providers": ["email"]}',
      '{"full_name": "Super Administrator"}',
      NOW(),
      '', '', '', '', '', '', '',  -- token columns must never be NULL
      NOW(),
      NOW()
    );

  ELSE
    UPDATE auth.users
      SET encrypted_password = crypt('Gso_Admin_2026', gen_salt('bf')),
          raw_app_meta_data = '{"provider": "email", "providers": ["email"]}',
          raw_user_meta_data = '{"full_name": "Super Administrator"}',
          email_confirmed_at = NOW(),
          instance_id = '00000000-0000-0000-0000-000000000000',
          updated_at = NOW()
      WHERE id = super_admin_user_id;
  END IF;


  -- Ensure identity exists (required for dashboard visibility and login)
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    uuid_generate_v4(),
    super_admin_user_id,
    format('{"sub":"%s","email":"%s"}', super_admin_user_id, 'cictstudentcouncil@isufst.edu.ph')::jsonb,
    'email',
    'cictstudentcouncil@isufst.edu.ph',
    NOW(),
    NOW(),
    NOW()
  )
  ON CONFLICT (provider, provider_id) DO NOTHING;



  -- Upsert profile (handles case where trigger might have already created it)
  INSERT INTO profiles (id, full_name, email, is_approved, is_active, created_at, updated_at)
  VALUES (
    super_admin_user_id,
    'Super Administrator',
    'cictstudentcouncil@isufst.edu.ph',
    true,
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      email = EXCLUDED.email,
      is_approved = EXCLUDED.is_approved,
      is_active = EXCLUDED.is_active,
      updated_at = NOW();


  SELECT id
    INTO super_admin_role_id
    FROM roles
    WHERE name = 'super_admin';

  IF super_admin_role_id IS NOT NULL THEN
    INSERT INTO user_roles (user_id, role_id)
    VALUES (super_admin_user_id, super_admin_role_id)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
