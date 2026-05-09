-- ============================================================
-- Migration 001: Roles, Departments, Profiles, User Roles
-- Run this FIRST in Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for full-text search

-- ── Departments (must be before profiles due to FK) ──────────
CREATE TABLE departments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT UNIQUE NOT NULL,
  code        TEXT UNIQUE,
  head_id     UUID,                         -- FK added after profiles
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Roles (Super Admin CRUD) ──────────────────────────────────
CREATE TABLE roles (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT UNIQUE NOT NULL,         -- slug: 'super_admin'
  display_name TEXT NOT NULL,               -- 'Super Administrator'
  description  TEXT,
  permissions  JSONB NOT NULL DEFAULT '{}',
  is_system    BOOLEAN NOT NULL DEFAULT false, -- system roles cannot be deleted
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── User Profiles (extends auth.users) ───────────────────────
CREATE TABLE profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name           TEXT NOT NULL,
  email               TEXT UNIQUE NOT NULL,
  phone               TEXT,
  department_id       UUID REFERENCES departments(id) ON DELETE SET NULL,
  employee_student_id TEXT,
  avatar_url          TEXT,
  is_approved         BOOLEAN NOT NULL DEFAULT false,
  is_active           BOOLEAN NOT NULL DEFAULT true,
  approved_by         UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approved_at         TIMESTAMPTZ,
  rejection_reason    TEXT,
  last_seen_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Now add head_id FK to departments
ALTER TABLE departments
  ADD CONSTRAINT departments_head_id_fkey
  FOREIGN KEY (head_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- ── User ↔ Role mapping ───────────────────────────────────────
CREATE TABLE user_roles (
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role_id     UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_profiles_email       ON profiles(email);
CREATE INDEX idx_profiles_approved    ON profiles(is_approved);
CREATE INDEX idx_profiles_department  ON profiles(department_id);
CREATE INDEX idx_user_roles_user      ON user_roles(user_id);
CREATE INDEX idx_user_roles_role      ON user_roles(role_id);

-- ── Updated-at trigger ────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_departments_updated_at
  BEFORE UPDATE ON departments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_roles_updated_at
  BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Auto-create profile on auth.users insert ─────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── Row Level Security ────────────────────────────────────────
ALTER TABLE profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles   ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user has a role
CREATE OR REPLACE FUNCTION has_role(role_name TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name = role_name
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: check if current user has any of several roles
CREATE OR REPLACE FUNCTION has_any_role(role_names TEXT[])
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name = ANY(role_names)
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Profiles policies
CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "profiles_select_staff"
  ON profiles FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'department_head']));

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_admin"
  ON profiles FOR UPDATE
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- Roles policies (read-only for all authenticated; write only super_admin)
CREATE POLICY "roles_select_all"
  ON roles FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "roles_write_super_admin"
  ON roles FOR ALL
  USING (has_role('super_admin'));

-- Departments policies
CREATE POLICY "departments_select_all"
  ON departments FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "departments_write_admin"
  ON departments FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- User roles policies
CREATE POLICY "user_roles_select_own"
  ON user_roles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "user_roles_select_staff"
  ON user_roles FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

CREATE POLICY "user_roles_write_admin"
  ON user_roles FOR ALL
  USING (has_role('super_admin'));
