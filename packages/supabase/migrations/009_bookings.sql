-- ============================================================
-- Migration 009: Booking System
-- ============================================================

-- ── Booking Status Enum ──────────────────────────────────────────
CREATE TYPE booking_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');

-- ── Bookings Table ───────────────────────────────────────────────
CREATE TABLE bookings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  room_id        UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  start_time     TIMESTAMPTZ NOT NULL,
  end_time       TIMESTAMPTZ NOT NULL,
  status         booking_status NOT NULL DEFAULT 'pending',
  attachment_url TEXT,                                             -- URL to the approval letter
  approved_by    UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approval_date  TIMESTAMPTZ,
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT booking_time_check CHECK (end_time > start_time)
);

-- ── Indexes ──────────────────────────────────────────────────────
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_room ON bookings(room_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_time ON bookings(start_time, end_time);

-- ── Triggers ─────────────────────────────────────────────────────
CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── RLS ──────────────────────────────────────────────────────────
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Users can view their own bookings
CREATE POLICY "bookings_select_own"
  ON bookings FOR SELECT
  USING (user_id = auth.uid());

-- Users can create booking requests
CREATE POLICY "bookings_insert_auth"
  ON bookings FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- GSO Staff and Super Admins can manage all bookings
CREATE POLICY "bookings_all_staff"
  ON bookings FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- SSC / Support Center specific access if we want to define a separate role, 
-- but based on current roles, gso_staff handles administration.
