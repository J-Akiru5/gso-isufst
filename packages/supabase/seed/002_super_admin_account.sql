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
      created_at,
      updated_at
    ) VALUES (
      NULL,
      super_admin_user_id,
      'authenticated',
      'authenticated',
      'cictstudentcouncil@isufst.edu.ph',
      crypt('Gso_Admin_2026', gen_salt('bf')),
      '{"provider": "email", "providers": ["email"]}',
      '{"full_name": "Super Administrator"}',
      NOW(),
      NOW()
    );
  ELSE
    UPDATE auth.users
      SET encrypted_password = crypt('Gso_Admin_2026', gen_salt('bf')),
          raw_app_meta_data = '{"provider": "email", "providers": ["email"]}',
          raw_user_meta_data = '{"full_name": "Super Administrator"}',
          updated_at = NOW()
      WHERE id = super_admin_user_id;
  END IF;

  IF NOT user_exists THEN
    INSERT INTO profiles (id, full_name, email, is_approved, is_active, created_at, updated_at)
    VALUES (
      super_admin_user_id,
      'Super Administrator',
      'cictstudentcouncil@isufst.edu.ph',
      true,
      true,
      NOW(),
      NOW()
    );
  ELSE
    UPDATE profiles
      SET full_name = 'Super Administrator',
          email = 'cictstudentcouncil@isufst.edu.ph',
          is_approved = true,
          is_active = true,
          updated_at = NOW()
      WHERE id = super_admin_user_id;
  END IF;

  SELECT id
    INTO super_admin_role_id
    FROM roles
    WHERE name = 'super_admin';

  INSERT INTO user_roles (user_id, role_id)
  VALUES (super_admin_user_id, super_admin_role_id)
  ON CONFLICT DO NOTHING;
END $$;
