-- ============================================================
-- Migration 003: Maintenance Request System
-- Run AFTER 002_buildings_rooms.sql
-- ============================================================

-- ── Maintenance Categories (Super Admin CRUD) ─────────────────
CREATE TABLE maintenance_categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT UNIQUE NOT NULL,    -- e.g., "Electrical"
  icon        TEXT,                   -- icon name/emoji
  description TEXT,
  color       TEXT,                   -- hex color for UI badge
  is_active   BOOLEAN NOT NULL DEFAULT true,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Maintenance Requests ──────────────────────────────────────
CREATE TABLE maintenance_requests (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_number  TEXT UNIQUE NOT NULL,  -- e.g., "MR-2026-0001"
  requester_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  category_id     UUID REFERENCES maintenance_categories(id) ON DELETE SET NULL,
  building_id     UUID REFERENCES buildings(id) ON DELETE SET NULL,
  room_id         UUID REFERENCES rooms(id) ON DELETE SET NULL,
  location_detail TEXT,                  -- extra detail beyond room
  title           TEXT NOT NULL,
  description     TEXT NOT NULL,
  priority_level  TEXT NOT NULL DEFAULT 'Medium'
                  CHECK (priority_level IN ('Low', 'Medium', 'High', 'Urgent')),
  status          TEXT NOT NULL DEFAULT 'Submitted'
                  CHECK (status IN (
                    'Draft', 'Submitted', 'Pending_HOD',
                    'HOD_Approved', 'HOD_Rejected',
                    'Received_GSO', 'Assigned', 'In_Progress',
                    'Completed', 'Verified', 'Closed', 'Cancelled'
                  )),
  -- HOD workflow
  hod_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  hod_decided_at  TIMESTAMPTZ,
  hod_notes       TEXT,
  -- Assignment
  assigned_to     UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- technician
  assigned_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- gso_staff
  assigned_at     TIMESTAMPTZ,
  -- Completion
  completed_at    TIMESTAMPTZ,
  verified_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  verified_at     TIMESTAMPTZ,
  -- Rejection
  rejection_reason TEXT,
  -- Metadata
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Request Attachments (issue / progress / completion photos) ─
CREATE TABLE maintenance_attachments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id      UUID NOT NULL REFERENCES maintenance_requests(id) ON DELETE CASCADE,
  uploaded_by     UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  file_url        TEXT NOT NULL,
  file_name       TEXT,
  file_size       INTEGER,             -- bytes
  attachment_type TEXT NOT NULL
                  CHECK (attachment_type IN ('issue', 'progress', 'completion')),
  caption         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Real-time Progress Timeline ────────────────────────────────
CREATE TABLE maintenance_timeline (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id   UUID NOT NULL REFERENCES maintenance_requests(id) ON DELETE CASCADE,
  status       TEXT NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  metadata     JSONB DEFAULT '{}',     -- extra data (attachment urls, etc.)
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Auto-generate request number ──────────────────────────────
CREATE SEQUENCE maintenance_request_seq START 1;

CREATE OR REPLACE FUNCTION generate_request_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.request_number = 'MR-' || TO_CHAR(NOW(), 'YYYY') || '-' ||
                       LPAD(NEXTVAL('maintenance_request_seq')::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_maintenance_request_number
  BEFORE INSERT ON maintenance_requests
  FOR EACH ROW
  WHEN (NEW.request_number IS NULL OR NEW.request_number = '')
  EXECUTE FUNCTION generate_request_number();

-- ── Auto-create timeline entry on status change ───────────────
CREATE OR REPLACE FUNCTION log_maintenance_status_change()
RETURNS TRIGGER AS $$
DECLARE
  status_titles JSONB := '{
    "Draft":        "Request Drafted",
    "Submitted":    "Request Submitted",
    "Pending_HOD":  "Awaiting Department Head Approval",
    "HOD_Approved": "Approved by Department Head",
    "HOD_Rejected": "Rejected by Department Head",
    "Received_GSO": "Received by GSO Office",
    "Assigned":     "Technician Assigned",
    "In_Progress":  "Work In Progress",
    "Completed":    "Work Completed",
    "Verified":     "Request Verified",
    "Closed":       "Request Closed",
    "Cancelled":    "Request Cancelled"
  }';
BEGIN
  IF (TG_OP = 'INSERT') OR (OLD.status IS DISTINCT FROM NEW.status) THEN
    INSERT INTO maintenance_timeline (request_id, status, title, performed_by)
    VALUES (
      NEW.id,
      NEW.status,
      COALESCE(status_titles->>NEW.status, NEW.status),
      auth.uid()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_maintenance_timeline
  AFTER INSERT OR UPDATE OF status ON maintenance_requests
  FOR EACH ROW EXECUTE FUNCTION log_maintenance_status_change();

-- ── Updated-at ────────────────────────────────────────────────
CREATE TRIGGER trg_maintenance_categories_updated_at
  BEFORE UPDATE ON maintenance_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_maintenance_requests_updated_at
  BEFORE UPDATE ON maintenance_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_maintenance_requester  ON maintenance_requests(requester_id);
CREATE INDEX idx_maintenance_status     ON maintenance_requests(status);
CREATE INDEX idx_maintenance_priority   ON maintenance_requests(priority_level);
CREATE INDEX idx_maintenance_assigned   ON maintenance_requests(assigned_to);
CREATE INDEX idx_maintenance_category   ON maintenance_requests(category_id);
CREATE INDEX idx_maintenance_building   ON maintenance_requests(building_id);
CREATE INDEX idx_maintenance_created    ON maintenance_requests(created_at DESC);
CREATE INDEX idx_maintenance_timeline   ON maintenance_timeline(request_id, created_at DESC);
CREATE INDEX idx_maintenance_attachments ON maintenance_attachments(request_id);

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE maintenance_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_requests    ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_timeline    ENABLE ROW LEVEL SECURITY;

-- Categories: all read, admin write
CREATE POLICY "maint_categories_select"
  ON maintenance_categories FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "maint_categories_write_admin"
  ON maintenance_categories FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- Requests: own + staff/hod visibility
CREATE POLICY "maint_requests_select_own"
  ON maintenance_requests FOR SELECT
  USING (requester_id = auth.uid());

CREATE POLICY "maint_requests_select_staff"
  ON maintenance_requests FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'technician']));

CREATE POLICY "maint_requests_select_hod"
  ON maintenance_requests FOR SELECT
  USING (
    has_role('department_head') AND
    requester_id IN (
      SELECT id FROM profiles
      WHERE department_id IN (
        SELECT department_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "maint_requests_insert_auth"
  ON maintenance_requests FOR INSERT
  TO authenticated
  WITH CHECK (requester_id = auth.uid());

CREATE POLICY "maint_requests_update_staff"
  ON maintenance_requests FOR UPDATE
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'department_head', 'technician']));

-- Timeline: same visibility as requests
CREATE POLICY "maint_timeline_select_own"
  ON maintenance_timeline FOR SELECT
  USING (
    request_id IN (
      SELECT id FROM maintenance_requests WHERE requester_id = auth.uid()
    )
  );

CREATE POLICY "maint_timeline_select_staff"
  ON maintenance_timeline FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'technician', 'department_head']));

-- Attachments
CREATE POLICY "maint_attachments_select_own"
  ON maintenance_attachments FOR SELECT
  USING (uploaded_by = auth.uid() OR
    request_id IN (
      SELECT id FROM maintenance_requests WHERE requester_id = auth.uid()
    ));

CREATE POLICY "maint_attachments_select_staff"
  ON maintenance_attachments FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'technician']));

CREATE POLICY "maint_attachments_insert_auth"
  ON maintenance_attachments FOR INSERT
  TO authenticated
  WITH CHECK (uploaded_by = auth.uid());
