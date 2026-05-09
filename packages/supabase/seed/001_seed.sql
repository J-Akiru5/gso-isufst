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
  ('Administration Building',           'ADMIN',   'Main administrative offices'),
  ('College of Information and Computing Technology', 'CICT', 'IT and computing classrooms'),
  ('College of Agriculture',            'CA',      'Agriculture and related programs'),
  ('College of Engineering and Technology', 'CET', 'Engineering labs and workshops'),
  ('Library',                           'LIB',     'University library'),
  ('Gymnasium',                         'GYM',     'Sports and events hall'),
  ('Dormitory A',                       'DORMA',   'Student dormitory A'),
  ('Dormitory B',                       'DORMB',   'Student dormitory B'),
  ('GSO Building',                      'GSO',     'General Services Office'),
  ('Canteen',                           'CAN',     'University canteen')
ON CONFLICT (code) DO NOTHING;

-- ── Default Departments ────────────────────────────────────────
INSERT INTO departments (name, code, description) VALUES
  ('General Services Office',                   'GSO',   'Campus facilities and asset management'),
  ('College of Information and Computing Technology', 'CICT', 'IT and computing programs'),
  ('College of Agriculture',                    'CA',    'Agricultural programs'),
  ('College of Engineering and Technology',     'CET',   'Engineering programs'),
  ('Office of the University President',        'OUP',   'University leadership'),
  ('Human Resources',                           'HR',    'Personnel and employment'),
  ('Finance Office',                            'FIN',   'Budget and finance'),
  ('Academic Affairs',                          'AA',    'Curriculum and academics')
ON CONFLICT (name) DO NOTHING;
