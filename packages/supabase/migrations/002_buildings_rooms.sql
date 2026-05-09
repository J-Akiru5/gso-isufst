-- ============================================================
-- Migration 002: Buildings & Rooms (Location System)
-- Run AFTER 001_roles_profiles.sql
-- ============================================================

-- ── Buildings ─────────────────────────────────────────────────
CREATE TABLE buildings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT NOT NULL,
  code       TEXT UNIQUE,                 -- e.g., "CICT", "ADMIN"
  description TEXT,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Rooms ─────────────────────────────────────────────────────
CREATE TABLE rooms (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,              -- e.g., "Room 102", "Faculty Room"
  floor       INTEGER,
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(building_id, name)
);

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_rooms_building ON rooms(building_id);

-- ── Triggers ─────────────────────────────────────────────────
CREATE TRIGGER trg_buildings_updated_at
  BEFORE UPDATE ON buildings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_rooms_updated_at
  BEFORE UPDATE ON rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms     ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read locations (needed for forms)
CREATE POLICY "buildings_select_auth"
  ON buildings FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "rooms_select_auth"
  ON rooms FOR SELECT
  TO authenticated USING (true);

-- Only admins can manage locations
CREATE POLICY "buildings_write_admin"
  ON buildings FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

CREATE POLICY "rooms_write_admin"
  ON rooms FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));
