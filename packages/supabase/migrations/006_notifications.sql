-- ============================================================
-- Migration 006: Notifications & Push Tokens
-- Run AFTER 005_borrowing.sql
-- ============================================================

-- ── In-App Notifications ──────────────────────────────────────
CREATE TABLE notifications (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  body           TEXT NOT NULL,
  type           TEXT NOT NULL DEFAULT 'system'
                 CHECK (type IN ('maintenance', 'loan', 'inventory', 'system', 'approval')),
  -- Reference to related entity
  reference_type TEXT CHECK (reference_type IN ('maintenance_request', 'equipment_loan', 'inventory_item', 'profile')),
  reference_id   UUID,
  -- State
  is_read        BOOLEAN NOT NULL DEFAULT false,
  read_at        TIMESTAMPTZ,
  -- Metadata (for deep linking)
  action_url     TEXT,
  metadata       JSONB DEFAULT '{}',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── FCM Push Tokens ───────────────────────────────────────────
CREATE TABLE push_tokens (
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token      TEXT NOT NULL,
  platform   TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_id  TEXT,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_notifications_user     ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread   ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_ref      ON notifications(reference_type, reference_id);
CREATE INDEX idx_push_tokens_user       ON push_tokens(user_id) WHERE is_active = true;

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens   ENABLE ROW LEVEL SECURITY;

-- Notifications: users see only their own
CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Only service role / edge functions insert notifications
CREATE POLICY "notifications_insert_service"
  ON notifications FOR INSERT
  WITH CHECK (has_role('super_admin') OR auth.role() = 'service_role');

-- Push tokens: users manage their own
CREATE POLICY "push_tokens_own"
  ON push_tokens FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "push_tokens_service"
  ON push_tokens FOR SELECT
  USING (auth.role() = 'service_role');

-- ── Enable Realtime on key tables ─────────────────────────────
-- Run these in Supabase Dashboard → Database → Replication
-- or via: ALTER PUBLICATION supabase_realtime ADD TABLE <table>;

ALTER PUBLICATION supabase_realtime ADD TABLE maintenance_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE maintenance_timeline;
ALTER PUBLICATION supabase_realtime ADD TABLE equipment_loans;
ALTER PUBLICATION supabase_realtime ADD TABLE loan_timeline;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
