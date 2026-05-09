-- ============================================================
-- Migration 004: Inventory Management System
-- Run AFTER 003_maintenance.sql
-- ============================================================

-- ── Inventory Categories (Super Admin CRUD) ───────────────────
CREATE TABLE inventory_categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT UNIQUE NOT NULL,
  description TEXT,
  icon        TEXT,
  color       TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Inventory Items ───────────────────────────────────────────
CREATE TABLE inventory_items (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_code          TEXT UNIQUE NOT NULL,        -- e.g., "GSO-PROJ-001"
  name               TEXT NOT NULL,
  description        TEXT,
  category_id        UUID REFERENCES inventory_categories(id) ON DELETE SET NULL,
  -- Physical details
  serial_number      TEXT,
  model              TEXT,
  manufacturer       TEXT,
  -- Acquisition
  acquisition_date   DATE,
  acquisition_cost   DECIMAL(12, 2),
  funding_source     TEXT,                        -- e.g., "CHED Grant 2024"
  purchase_order_no  TEXT,
  -- Condition & Location
  condition          TEXT NOT NULL DEFAULT 'Good'
                     CHECK (condition IN ('New', 'Good', 'Fair', 'Poor', 'For_Disposal')),
  building_id        UUID REFERENCES buildings(id) ON DELETE SET NULL,
  room_id            UUID REFERENCES rooms(id) ON DELETE SET NULL,
  location_detail    TEXT,
  -- Borrowing
  is_borrowable      BOOLEAN NOT NULL DEFAULT false,
  quantity           INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  available_quantity INTEGER NOT NULL DEFAULT 1 CHECK (available_quantity >= 0),
  -- Media
  image_url          TEXT,
  -- Status
  is_active          BOOLEAN NOT NULL DEFAULT true,
  notes              TEXT,
  -- Audit
  created_by         UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Ensure available <= quantity
  CONSTRAINT available_lte_quantity CHECK (available_quantity <= quantity)
);

-- ── Inventory Audit Log ───────────────────────────────────────
CREATE TABLE inventory_audit_log (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id     UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  action      TEXT NOT NULL CHECK (action IN ('created', 'updated', 'condition_changed', 'location_changed', 'quantity_changed')),
  old_values  JSONB,
  new_values  JSONB,
  performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Auto-generate item code ───────────────────────────────────
CREATE SEQUENCE inventory_item_seq START 1;

CREATE OR REPLACE FUNCTION generate_item_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.item_code IS NULL OR NEW.item_code = '' THEN
    NEW.item_code = 'GSO-' || TO_CHAR(NOW(), 'YYYY') || '-' ||
                   LPAD(NEXTVAL('inventory_item_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_item_code
  BEFORE INSERT ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION generate_item_code();

-- ── Audit log trigger ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION log_inventory_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO inventory_audit_log (item_id, action, new_values, performed_by)
    VALUES (NEW.id, 'created', row_to_json(NEW)::JSONB, auth.uid());
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO inventory_audit_log (item_id, action, old_values, new_values, performed_by)
    VALUES (NEW.id, 'updated', row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_inventory_audit
  AFTER INSERT OR UPDATE ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION log_inventory_change();

-- ── Updated-at triggers ───────────────────────────────────────
CREATE TRIGGER trg_inventory_categories_updated_at
  BEFORE UPDATE ON inventory_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_inventory_items_updated_at
  BEFORE UPDATE ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_inventory_category   ON inventory_items(category_id);
CREATE INDEX idx_inventory_condition  ON inventory_items(condition);
CREATE INDEX idx_inventory_building   ON inventory_items(building_id);
CREATE INDEX idx_inventory_borrowable ON inventory_items(is_borrowable) WHERE is_borrowable = true;
CREATE INDEX idx_inventory_active     ON inventory_items(is_active) WHERE is_active = true;
CREATE INDEX idx_inventory_name_trgm  ON inventory_items USING gin(name gin_trgm_ops);
CREATE INDEX idx_inventory_audit_item ON inventory_audit_log(item_id, created_at DESC);

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_audit_log  ENABLE ROW LEVEL SECURITY;

-- Categories: all read, admin write
CREATE POLICY "inv_categories_select"
  ON inventory_categories FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "inv_categories_write_admin"
  ON inventory_categories FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- Inventory items: all authenticated can read active items
CREATE POLICY "inv_items_select_auth"
  ON inventory_items FOR SELECT
  TO authenticated USING (is_active = true);

CREATE POLICY "inv_items_select_all_admin"
  ON inventory_items FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

CREATE POLICY "inv_items_write_admin"
  ON inventory_items FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- Audit log: admin only
CREATE POLICY "inv_audit_select_admin"
  ON inventory_audit_log FOR SELECT
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));
