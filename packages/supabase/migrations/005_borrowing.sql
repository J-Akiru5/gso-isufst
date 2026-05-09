-- ============================================================
-- Migration 005: Equipment Borrowing System
-- Run AFTER 004_inventory.sql
-- ============================================================

-- ── Equipment Loans ───────────────────────────────────────────
CREATE TABLE equipment_loans (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_number           TEXT UNIQUE NOT NULL,     -- e.g., "EL-2026-0001"
  item_id               UUID NOT NULL REFERENCES inventory_items(id) ON DELETE RESTRICT,
  borrower_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  loan_type             TEXT NOT NULL DEFAULT 'reservation'
                        CHECK (loan_type IN ('reservation', 'walk_in')),
  quantity_borrowed     INTEGER NOT NULL DEFAULT 1 CHECK (quantity_borrowed > 0),
  purpose               TEXT NOT NULL,
  -- Dates
  expected_pickup_date  DATE,
  expected_return_date  DATE NOT NULL,
  actual_pickup_date    DATE,
  actual_return_date    DATE,
  -- Approval workflow (HOD always required)
  status                TEXT NOT NULL DEFAULT 'Pending_HOD'
                        CHECK (status IN (
                          'Pending_HOD', 'HOD_Approved', 'HOD_Rejected',
                          'Pending_GSO', 'GSO_Approved', 'GSO_Rejected',
                          'Released', 'In_Use', 'Overdue',
                          'Returned', 'Inspected', 'Closed', 'Cancelled'
                        )),
  -- Release & return
  condition_on_release  TEXT CHECK (condition_on_release IN ('New', 'Good', 'Fair', 'Poor')),
  condition_on_return   TEXT CHECK (condition_on_return IN ('New', 'Good', 'Fair', 'Poor', 'Damaged')),
  damage_notes          TEXT,
  released_by           UUID REFERENCES profiles(id) ON DELETE SET NULL,
  released_at           TIMESTAMPTZ,
  returned_to           UUID REFERENCES profiles(id) ON DELETE SET NULL,
  returned_at           TIMESTAMPTZ,
  inspected_by          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  inspected_at          TIMESTAMPTZ,
  -- Metadata
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Approval Records ──────────────────────────────────────────
CREATE TABLE loan_approvals (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id     UUID NOT NULL REFERENCES equipment_loans(id) ON DELETE CASCADE,
  approver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  level       TEXT NOT NULL CHECK (level IN ('HOD', 'GSO')),
  decision    TEXT NOT NULL CHECK (decision IN ('Approved', 'Rejected')),
  notes       TEXT,
  decided_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(loan_id, level)  -- one decision per level per loan
);

-- ── Real-time Loan Timeline ───────────────────────────────────
CREATE TABLE loan_timeline (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id      UUID NOT NULL REFERENCES equipment_loans(id) ON DELETE CASCADE,
  status       TEXT NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  metadata     JSONB DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Auto-generate loan number ─────────────────────────────────
CREATE SEQUENCE equipment_loan_seq START 1;

CREATE OR REPLACE FUNCTION generate_loan_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.loan_number = 'EL-' || TO_CHAR(NOW(), 'YYYY') || '-' ||
                   LPAD(NEXTVAL('equipment_loan_seq')::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_loan_number
  BEFORE INSERT ON equipment_loans
  FOR EACH ROW
  WHEN (NEW.loan_number IS NULL OR NEW.loan_number = '')
  EXECUTE FUNCTION generate_loan_number();

-- ── Auto-create timeline on status change ─────────────────────
CREATE OR REPLACE FUNCTION log_loan_status_change()
RETURNS TRIGGER AS $$
DECLARE
  status_titles JSONB := '{
    "Pending_HOD":  "Awaiting Department Head Approval",
    "HOD_Approved": "Approved by Department Head",
    "HOD_Rejected": "Rejected by Department Head",
    "Pending_GSO":  "Awaiting GSO Approval",
    "GSO_Approved": "Approved by GSO — Ready for Pickup",
    "GSO_Rejected": "Rejected by GSO",
    "Released":     "Equipment Released to Borrower",
    "In_Use":       "Equipment Currently In Use",
    "Overdue":      "Return Overdue — Please Return Immediately",
    "Returned":     "Equipment Returned",
    "Inspected":    "Equipment Inspected and Cleared",
    "Closed":       "Loan Closed",
    "Cancelled":    "Loan Request Cancelled"
  }';
BEGIN
  IF (TG_OP = 'INSERT') OR (OLD.status IS DISTINCT FROM NEW.status) THEN
    INSERT INTO loan_timeline (loan_id, status, title, performed_by)
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

CREATE TRIGGER trg_loan_timeline
  AFTER INSERT OR UPDATE OF status ON equipment_loans
  FOR EACH ROW EXECUTE FUNCTION log_loan_status_change();

-- ── Manage available_quantity on inventory ────────────────────
CREATE OR REPLACE FUNCTION adjust_inventory_availability()
RETURNS TRIGGER AS $$
BEGIN
  -- When released, decrement available quantity
  IF NEW.status = 'Released' AND (OLD.status IS DISTINCT FROM 'Released') THEN
    UPDATE inventory_items
    SET available_quantity = available_quantity - NEW.quantity_borrowed
    WHERE id = NEW.item_id;
  END IF;

  -- When returned/cancelled/rejected, restore available quantity
  IF NEW.status IN ('Returned', 'Closed', 'Cancelled', 'GSO_Rejected', 'HOD_Rejected')
     AND OLD.status = 'Released' THEN
    UPDATE inventory_items
    SET available_quantity = available_quantity + NEW.quantity_borrowed
    WHERE id = NEW.item_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_loan_availability
  AFTER UPDATE OF status ON equipment_loans
  FOR EACH ROW EXECUTE FUNCTION adjust_inventory_availability();

-- ── Updated-at triggers ───────────────────────────────────────
CREATE TRIGGER trg_equipment_loans_updated_at
  BEFORE UPDATE ON equipment_loans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_loans_borrower    ON equipment_loans(borrower_id);
CREATE INDEX idx_loans_item        ON equipment_loans(item_id);
CREATE INDEX idx_loans_status      ON equipment_loans(status);
CREATE INDEX idx_loans_return_date ON equipment_loans(expected_return_date);
CREATE INDEX idx_loans_created     ON equipment_loans(created_at DESC);
CREATE INDEX idx_loan_timeline     ON loan_timeline(loan_id, created_at DESC);
CREATE INDEX idx_loan_approvals    ON loan_approvals(loan_id);

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE equipment_loans  ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_approvals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_timeline     ENABLE ROW LEVEL SECURITY;

-- Loans
CREATE POLICY "loans_select_own"
  ON equipment_loans FOR SELECT
  USING (borrower_id = auth.uid());

CREATE POLICY "loans_select_staff"
  ON equipment_loans FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

CREATE POLICY "loans_select_hod"
  ON equipment_loans FOR SELECT
  USING (
    has_role('department_head') AND
    borrower_id IN (
      SELECT id FROM profiles
      WHERE department_id IN (
        SELECT department_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "loans_insert_auth"
  ON equipment_loans FOR INSERT
  TO authenticated
  WITH CHECK (borrower_id = auth.uid());

CREATE POLICY "loans_update_staff"
  ON equipment_loans FOR UPDATE
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'department_head']));

-- Approvals
CREATE POLICY "approvals_select_staff"
  ON loan_approvals FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'department_head']));

CREATE POLICY "approvals_insert_staff"
  ON loan_approvals FOR INSERT
  WITH CHECK (has_any_role(ARRAY['super_admin', 'gso_staff', 'department_head']));

-- Timeline
CREATE POLICY "loan_timeline_select_own"
  ON loan_timeline FOR SELECT
  USING (
    loan_id IN (
      SELECT id FROM equipment_loans WHERE borrower_id = auth.uid()
    )
  );

CREATE POLICY "loan_timeline_select_staff"
  ON loan_timeline FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'department_head']));
