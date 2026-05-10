-- ============================================================
-- Seed Data: Default Roles, Categories, and Sample Data
-- Run AFTER all 001–006 migrations
-- ============================================================

-- ── Default System Roles ──────────────────────────────────────
INSERT INTO roles (name, display_name, description, is_system, permissions) VALUES
  ('super_admin', 'Super Administrator', 'Full system control — cannot be deleted', true,
    '{"all": true}'
  ),
  ('gso_staff', 'GSO Staff', 'General Services Office personnel — manages requests and inventory', true,
    '{"maintenance": ["read","update","assign"], "inventory": ["all"], "loans": ["read","update","approve"], "users": ["read"]}'
  ),
  ('department_head', 'Department Head', 'Approves requests from their department', true,
    '{"maintenance": ["read","approve"], "loans": ["read","approve"]}'
  ),
  ('faculty', 'Faculty', 'Can submit maintenance requests and borrow equipment', true,
    '{"maintenance": ["create","read_own"], "loans": ["create","read_own"], "inventory": ["read"]}'
  ),
  ('student', 'Student', 'Can submit maintenance requests and borrow equipment', true,
    '{"maintenance": ["create","read_own"], "loans": ["create","read_own"], "inventory": ["read"]}'
  ),
  ('technician', 'Technician / Maintenance Worker', 'Executes assigned maintenance tasks and updates progress', true,
    '{"maintenance": ["read_assigned","update_progress"]}'
  )
ON CONFLICT (name) DO NOTHING;

-- ── Default Maintenance Categories ───────────────────────────
INSERT INTO maintenance_categories (name, icon, color, sort_order) VALUES
  ('Electrical',          '⚡', '#f59e0b', 1),
  ('Plumbing',            '🔧', '#2a80af', 2),
  ('Carpentry',           '🪵', '#92400e', 3),
  ('Air Conditioning / HVAC', '❄️', '#06b6d4', 4),
  ('Structural / Civil',  '🏗️', '#64748b', 5),
  ('IT / Network',        '💻', '#8b5cf6', 6),
  ('Grounds / Landscaping', '🌿', '#16a34a', 7),
  ('Painting',            '🎨', '#ec4899', 8),
  ('Furniture',           '🪑', '#f97316', 9),
  ('Pest Control',        '🐜', '#dc2626', 10),
  ('Cleaning / Sanitation', '🧹', '#0891b2', 11),
  ('Other',               '📋', '#94a3b8', 12)
ON CONFLICT (name) DO NOTHING;

-- ── Default Inventory Categories ─────────────────────────────
INSERT INTO inventory_categories (name, icon, color, sort_order) VALUES
  ('Audio-Visual Equipment',  '📽️', '#8b5cf6', 1),
  ('Laboratory Equipment',    '🔬', '#06b6d4', 2),
  ('Office Equipment',        '🖨️', '#2a80af', 3),
  ('Furniture',               '🪑', '#f97316', 4),
  ('Power Tools',             '🔨', '#f59e0b', 5),
  ('Sports Equipment',        '⚽', '#16a34a', 6),
  ('Cleaning Equipment',      '🧹', '#0891b2', 7),
  ('Vehicles',                '🚗', '#64748b', 8),
  ('IT / Computing',          '💻', '#7c3aed', 9),
  ('Medical / First Aid',     '🏥', '#dc2626', 10),
  ('Other',                   '📦', '#94a3b8', 11)
ON CONFLICT (name) DO NOTHING;

-- ── Default Buildings (Dingle Campus) ────────────────────────
INSERT INTO buildings (name, code, description) VALUES
  ('College of Agriculture',                    'CA',      'Agriculture department building'),
  ('College of Information and Communications Technology', 'CICT', 'ICT department building'),
  ('College of Hospitality Management',         'CHM',     'Hospitality management department building'),
  ('College of Education',                      'CED',     'Education department building'),
  ('Administration Building',                   'ADMIN',   'Houses MIS, Supply, Procurement, Research and Development, and Campus Administrator offices'),
  ('Knowledge Management Hub',                  'KMH',     'Library and knowledge services'),
  ('Clinic',                                    'CLIN',    'Campus health services'),
  ('Cultural Center',                           'CULT',    'Cultural and student activities venue'),
  ('Stage',                                     'STAGE',   'Performance and event stage'),
  ('GSO Shop',                                  'GSO_SHOP', 'General Services Office shop and support area'),
  ('Garage',                                    'GAR',     'Vehicle and equipment garage'),
  ('Cooperative',                               'COOP',    'Canteen and cooperative services'),
  ('PTEA Hall',                                 'PTEA',    'Events and assembly hall')
ON CONFLICT (code) DO NOTHING;

-- ── Default Departments ────────────────────────────────────────
INSERT INTO departments (name, code, description) VALUES
  ('College of Agriculture',                    'CA',    'Agricultural programs'),
  ('College of Information and Communications Technology', 'CICT', 'Information and communications technology programs'),
  ('College of Hospitality Management',         'CHM',   'Hospitality management programs'),
  ('College of Education',                      'CED',   'Teacher education and related programs'),
  ('Supply Office',                             'SUP',   'Supply and materials management'),
  ('Procurement Office',                        'PROC',  'Procurement and purchasing operations'),
  ('Research and Development Office',           'RDO',   'Research and development coordination'),
  ('MIS Office',                                'MIS',   'Management information systems and IT support'),
  ('Office of Campus Administrator',            'OCA',   'Campus administration and operations')
ON CONFLICT (name) DO NOTHING;
