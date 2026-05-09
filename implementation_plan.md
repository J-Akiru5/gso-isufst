# ISUFST Management Portal — Implementation Plan

## Overview

A full-stack institutional management system for the General Services Office of ISUFST Dingle Campus. The system handles **Maintenance Requests**, **Equipment Borrowing**, and **Inventory Management** with multi-level approval workflows, real-time progress tracking, and role-based access control.

| Layer | Technology |
|-------|-----------|
| Monorepo | Turborepo |
| Web Dashboard | Next.js 15 (App Router), Tailwind CSS v4, shadcn/ui |
| Mobile App | Flutter (Android + iOS) |
| Backend | Supabase Cloud (PostgreSQL, Auth, Realtime, Storage, Edge Functions) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Reporting | jsPDF, SheetJS (xlsx), csv-stringify |
| Deployment | Vercel (web), App Store / Play Store (mobile) |

---

## User Roles

| Role | Access | Key Permissions |
|------|--------|----------------|
| Student | Mobile + Web | Submit maintenance requests, borrow equipment |
| Faculty | Mobile + Web | Same as student + higher borrowing privileges |
| Department Head | Mobile + Web | Approve/reject requests from their department |
| GSO Staff | Web + Mobile | Manage requests, assign technicians, manage inventory |
| Technician | Mobile + Web | View assignments, update progress, upload photos |
| Super Admin | Web + Mobile | Full system control, CRUD roles/categories/settings |

---

## Monorepo Structure

```
GSO-ISUFST/
├── apps/
│   ├── web-dashboard/              # Next.js 15
│   │   ├── src/
│   │   │   ├── app/                # App Router pages
│   │   │   │   ├── (auth)/         # Login, Register
│   │   │   │   ├── (dashboard)/    # Protected dashboard layout
│   │   │   │   │   ├── overview/
│   │   │   │   │   ├── maintenance/
│   │   │   │   │   ├── inventory/
│   │   │   │   │   ├── borrowing/
│   │   │   │   │   ├── users/
│   │   │   │   │   ├── reports/
│   │   │   │   │   └── settings/   # Super Admin config
│   │   │   │   └── api/            # Route handlers
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── lib/
│   │   │   └── styles/
│   │   ├── public/                 # Logo, assets
│   │   ├── tailwind.config.ts
│   │   └── package.json
│   │
│   └── mobile_app/                 # Flutter
│       ├── lib/
│       │   ├── core/               # Theme, constants, utils
│       │   ├── features/           # Feature-based modules
│       │   │   ├── auth/
│       │   │   ├── maintenance/
│       │   │   ├── inventory/
│       │   │   ├── borrowing/
│       │   │   ├── notifications/
│       │   │   └── profile/
│       │   ├── models/
│       │   ├── providers/          # Riverpod providers
│       │   ├── services/           # Supabase service layer
│       │   └── widgets/            # Shared widgets
│       ├── android/
│       ├── ios/
│       └── pubspec.yaml
│
├── packages/
│   ├── supabase/                   # Database contract
│   │   ├── migrations/             # SQL migration files
│   │   ├── seed/                   # Seed data (roles, categories)
│   │   ├── functions/              # Supabase Edge Functions
│   │   └── types/                  # Generated TypeScript types
│   │
│   ├── design-tokens/              # Shared color/theme constants
│   │   ├── tokens.json             # Source of truth for colors
│   │   ├── tailwind.preset.js      # Tailwind preset (web)
│   │   └── flutter_tokens.dart     # Dart constants (mobile)
│   │
│   └── business-logic/             # Shared validation rules
│       ├── validation.ts           # Request validation schemas (Zod)
│       └── workflows.md            # Workflow documentation
│
├── turbo.json
├── package.json
├── .gitignore
└── .env.example
```

---

## Design Tokens

```json
{
  "colors": {
    "primary": "#003d62",
    "primary-light": "#d0e7f5",
    "secondary": "#2a80af",
    "dark": "#0f0d0e",
    "institutional": "#142d55",
    "vivid": "#0352bc",
    "success": "#16a34a",
    "warning": "#f59e0b",
    "danger": "#dc2626",
    "urgent": "#9333ea"
  },
  "font": "Inter, Arial, sans-serif"
}
```

---

## Database Schema (Supabase PostgreSQL)

### 1. Users & Roles

```sql
-- Roles (Super Admin CRUD)
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  permissions JSONB DEFAULT '{}',
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  department_id UUID REFERENCES departments(id),
  employee_student_id TEXT,
  avatar_url TEXT,
  is_approved BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Many-to-many user ↔ role
CREATE TABLE user_roles (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);

-- Departments
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  head_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. Locations

```sql
CREATE TABLE buildings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id UUID REFERENCES buildings(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  floor INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3. Maintenance Requests

```sql
CREATE TABLE maintenance_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  icon TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE maintenance_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number TEXT UNIQUE NOT NULL,
  requester_id UUID REFERENCES profiles(id) NOT NULL,
  category_id UUID REFERENCES maintenance_categories(id),
  building_id UUID REFERENCES buildings(id),
  room_id UUID REFERENCES rooms(id),
  location_detail TEXT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  priority_level TEXT DEFAULT 'Medium'
    CHECK (priority_level IN ('Low','Medium','High','Urgent')),
  status TEXT DEFAULT 'Submitted'
    CHECK (status IN (
      'Draft','Submitted','Pending_HOD','HOD_Approved','HOD_Rejected',
      'Received_GSO','Assigned','In_Progress','Completed',
      'Verified','Closed','Cancelled'
    )),
  assigned_to UUID REFERENCES profiles(id),
  assigned_by UUID REFERENCES profiles(id),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Photo evidence (issue / progress / completion)
CREATE TABLE maintenance_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES maintenance_requests(id) ON DELETE CASCADE,
  uploaded_by UUID REFERENCES profiles(id),
  file_url TEXT NOT NULL,
  attachment_type TEXT CHECK (attachment_type IN ('issue','progress','completion')),
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Real-time progress timeline (e-commerce style)
CREATE TABLE maintenance_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES maintenance_requests(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  performed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4. Inventory

```sql
CREATE TABLE inventory_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES inventory_categories(id),
  serial_number TEXT,
  acquisition_date DATE,
  acquisition_cost DECIMAL(12,2),
  funding_source TEXT,
  condition TEXT DEFAULT 'Good'
    CHECK (condition IN ('New','Good','Fair','Poor','For_Disposal')),
  building_id UUID REFERENCES buildings(id),
  room_id UUID REFERENCES rooms(id),
  is_borrowable BOOLEAN DEFAULT false,
  quantity INTEGER DEFAULT 1,
  available_quantity INTEGER DEFAULT 1,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 5. Equipment Borrowing

```sql
CREATE TABLE equipment_loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_number TEXT UNIQUE NOT NULL,
  item_id UUID REFERENCES inventory_items(id) NOT NULL,
  borrower_id UUID REFERENCES profiles(id) NOT NULL,
  loan_type TEXT DEFAULT 'reservation'
    CHECK (loan_type IN ('reservation','walk_in')),
  quantity_borrowed INTEGER DEFAULT 1,
  purpose TEXT,
  expected_pickup_date DATE,
  expected_return_date DATE NOT NULL,
  actual_return_date DATE,
  status TEXT DEFAULT 'Pending_HOD'
    CHECK (status IN (
      'Pending_HOD','HOD_Approved','HOD_Rejected',
      'Pending_GSO','GSO_Approved','GSO_Rejected',
      'Released','In_Use','Overdue',
      'Returned','Inspected','Closed','Cancelled'
    )),
  condition_on_release TEXT,
  condition_on_return TEXT,
  damage_notes TEXT,
  released_by UUID REFERENCES profiles(id),
  returned_to UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE loan_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id UUID REFERENCES equipment_loans(id) ON DELETE CASCADE,
  approver_id UUID REFERENCES profiles(id),
  level TEXT CHECK (level IN ('HOD','GSO')),
  decision TEXT CHECK (decision IN ('Approved','Rejected')),
  notes TEXT,
  decided_at TIMESTAMPTZ DEFAULT NOW()
);

-- Real-time progress timeline for loans
CREATE TABLE loan_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id UUID REFERENCES equipment_loans(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  performed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 6. Notifications

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT, -- 'maintenance','loan','system','approval'
  reference_type TEXT,
  reference_id UUID,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE push_tokens (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT CHECK (platform IN ('android','ios','web')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);
```

### Key RLS Policies (examples)

```sql
-- Users can only see their own profile
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins read all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.id
      WHERE ur.user_id = auth.uid()
      AND r.name IN ('super_admin','gso_staff'))
  );

-- Requesters see own requests; GSO/HOD see relevant ones
ALTER TABLE maintenance_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Requester reads own" ON maintenance_requests
  FOR SELECT USING (requester_id = auth.uid());
```

### Supabase Realtime

Enable Realtime on these tables for live updates:
- `maintenance_requests` (status changes)
- `maintenance_timeline` (new progress entries)
- `equipment_loans` (status changes)
- `loan_timeline` (new progress entries)
- `notifications` (new notifications)

---

## Phased Implementation

### Phase 1: Foundation & Infrastructure

> **Goal**: Monorepo scaffolding, Supabase setup, auth flow, shared packages.

#### Monorepo Setup
- Initialize Turborepo at `s:\Dev\Monorepo\GSO-ISUFST`
- Create `apps/web-dashboard` with Next.js 15 + Tailwind v4 + shadcn/ui
- Create `apps/mobile_app` with Flutter
- Create `packages/supabase` with migrations & seed
- Create `packages/design-tokens` with color/theme JSON
- Configure `turbo.json` with build/dev/lint pipelines

#### Supabase Configuration
- Create Supabase project (cloud)
- Run all migration SQL files
- Seed default roles: `student`, `faculty`, `department_head`, `gso_staff`, `technician`, `super_admin`
- Seed default maintenance categories
- Configure Auth (email + password, email verification optional)
- Set up Storage buckets: `avatars`, `maintenance-photos`, `inventory-images`

#### Auth Flow (Web)
- Registration page with role selection (Student/Faculty)
- Login page
- "Pending Approval" screen after registration
- Super Admin user approval dashboard
- Middleware to check `is_approved` + role-based route guards
- Profile setup page

#### Auth Flow (Mobile)
- Registration screen with role selection
- Login screen
- Pending approval state
- Profile setup screen

---

### Phase 2: Maintenance Requests

> **Goal**: Complete maintenance request lifecycle with real-time progress tracking.

#### Web Dashboard Pages
- **Kanban Board** (`/maintenance`): Columns for each status, drag-to-update
- **Request Detail** (`/maintenance/[id]`): Full info, timeline, photos, assignment
- **New Request Form**: Category, location (building → room), priority, description, photo upload
- **HOD Queue** (`/maintenance/approvals`): Pending requests from department members
- **Assignment Panel**: GSO staff assigns technician from dropdown
- **Category Management** (`/settings/maintenance-categories`): Super Admin CRUD

#### Mobile App Screens
- **Request List**: Filterable by status, pull-to-refresh
- **New Request**: Step-by-step form with camera integration
- **Request Detail**: Timeline view (e-commerce delivery style)
- **HOD Approval**: Approve/reject with notes
- **Technician View**: Assigned tasks, update progress, upload photos

#### Real-time Progress Tracking
Each status change creates a `maintenance_timeline` entry. The UI renders a vertical stepper:

```
✅ Request Submitted — May 10, 2026 8:00 AM
   "Broken AC unit in CICT Room 102"
✅ HOD Approved — May 10, 2026 9:30 AM
   "Approved by Dr. Santos"
✅ Received by GSO — May 10, 2026 10:00 AM
   "Received and logged by GSO Office"
✅ Technician Assigned — May 10, 2026 10:15 AM
   "Assigned to Juan Dela Cruz (HVAC Specialist)"
🔵 In Progress — May 10, 2026 2:00 PM
   "Compressor replacement underway" [📷 Photo]
⬜ Completed
⬜ Verified & Closed
```

Supabase Realtime subscription on `maintenance_timeline` pushes new entries to all connected clients instantly.

---

### Phase 3: Inventory & Equipment Borrowing

> **Goal**: Full inventory CRUD + equipment loan lifecycle with reservations.

#### Inventory (Web Dashboard)
- **Item List** (`/inventory`): Table with search, filter by category/condition/building
- **Item Detail** (`/inventory/[id]`): Full info, borrowing history, edit form
- **Add/Edit Item**: All fields including serial_number, acquisition_date, funding_source, condition
- **Category Management** (`/settings/inventory-categories`): Super Admin CRUD
- **Bulk Actions**: Mark multiple items for disposal, change location

#### Equipment Borrowing (Web + Mobile)
- **Browse Available** (`/borrowing`): Grid of borrowable items with availability
- **Reservation Form**: Select item, quantity, dates, purpose
- **Walk-in Processing**: GSO staff creates loan on behalf of borrower
- **Approval Queue**: HOD and GSO approval views
- **Loan Detail**: Timeline tracking (same pattern as maintenance)
- **Return Processing**: GSO staff records return, inspects condition

#### Loan Timeline (e-commerce style)

```
✅ Request Submitted — Reservation for Projector #3
✅ HOD Approved — Approved by Dept. Head
✅ GSO Approved — Equipment available, proceed to pickup
🔵 Released — Picked up by borrower
⬜ Return Due — May 15, 2026
⬜ Returned & Inspected
```

---

### Phase 4: Notifications & Real-time

> **Goal**: In-app + push notifications across web and mobile.

#### Notification Triggers (via Supabase Edge Functions / Database Triggers)
| Event | Notify |
|-------|--------|
| New maintenance request | Department Head |
| HOD approves/rejects | Requester + GSO Staff |
| Technician assigned | Technician |
| Progress update | Requester |
| Request completed | Requester + GSO Staff |
| New loan request | Department Head |
| HOD approves loan | Borrower + GSO Staff |
| GSO approves loan | Borrower |
| Loan overdue | Borrower + GSO Staff |

#### Implementation
- **Supabase Edge Function**: `handle-notification` — triggered by database webhooks
- **FCM Integration**: Edge function sends push via FCM for mobile
- **Web**: Supabase Realtime subscription on `notifications` table
- **Mobile**: `firebase_messaging` + `flutter_local_notifications`
- **Notification Bell**: Badge count in header (web) and app bar (mobile)
- **Notification Center**: Drawer/page listing all notifications with read/unread state

---

### Phase 5: Reporting & Analytics

> **Goal**: Dashboard KPIs + exportable reports.

#### Dashboard Overview (`/overview`)
- **KPI Cards**: Total requests (this month), pending approvals, active loans, overdue items
- **Charts** (Recharts):
  - Monthly maintenance requests (bar chart, by category)
  - Average resolution time (line chart, trend)
  - Equipment utilization rate (donut chart)
  - Requests by building (horizontal bar)
- **Recent Activity Feed**: Live stream of latest actions

#### Reports Page (`/reports`)
- **Maintenance Report**: Filter by date range, building, category, status
- **Inventory Report**: Current asset listing with conditions
- **Borrowing Report**: Active loans, overdue items, borrowing frequency
- **Export Formats**: PDF (jsPDF + autoTable), Excel (SheetJS), CSV

---

### Phase 6: Super Admin Settings & Polish

> **Goal**: Full admin configurability + dark mode + final polish.

#### Super Admin Settings (`/settings`)
- **Role Management**: CRUD roles, assign permissions
- **User Management**: Approve/reject registrations, assign roles, deactivate users
- **Maintenance Categories**: Add/edit/delete/toggle active
- **Inventory Categories**: Add/edit/delete/toggle active
- **Buildings & Rooms**: CRUD locations
- **Departments**: CRUD departments, assign heads
- **System Settings**: App name, notifications toggle, etc.

#### Dark Mode
- Tailwind dark mode with `class` strategy
- Theme toggle in header (Light / Dark / System)
- All components use CSS variables mapped to dark variants
- Flutter: `ThemeData` with dark/light variants from design tokens

#### Polish
- Loading skeletons for all data-fetching states
- Empty states with illustrations
- Error boundaries with friendly messages
- Responsive design: dashboard works on tablet+, mobile app is phone-first
- Page transition animations (web: CSS, mobile: Flutter Hero/shared axis)
- Micro-interactions on buttons, cards, status badges

---

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| **shadcn/ui** over MUI/Chakra | Tree-shakeable, copy-paste components, full Tailwind integration |
| **Riverpod** over BLoC (Flutter) | Simpler syntax, better testability, compile-safe |
| **Supabase Realtime** over polling | Native WebSocket support, zero config for Postgres Changes |
| **Edge Functions** for notifications | Runs close to DB, no separate server needed |
| **jsPDF + SheetJS** over server-side | Client-side generation avoids server load for reports |
| **Kanban board** with CSS Grid | Lightweight, no heavy DnD library dependency initially |

---

## Verification Plan

### Automated
- `turbo build` — all apps and packages compile without errors
- `turbo lint` — no linting violations
- Supabase migration dry-run on staging project
- Flutter `flutter analyze` — no static analysis issues

### Manual Testing
- **Auth flow**: Register → pending → admin approve → login → role-based redirect
- **Maintenance**: Submit → HOD approve → GSO assign → technician update → complete → verify timeline
- **Borrowing**: Reserve → HOD approve → GSO approve → release → return → inspect
- **Real-time**: Open two browsers, change status in one, verify instant update in other
- **Mobile**: Same workflows on Android emulator + iOS simulator
- **Dark mode**: Toggle and verify all pages render correctly
- **Reports**: Generate PDF/Excel/CSV and verify data accuracy
- **Notifications**: Trigger events, verify in-app + push delivery

### Browser Testing
- Chrome, Firefox, Safari (web dashboard)
- Android Chrome, iOS Safari (responsive check)

---

## Open Questions

> [!IMPORTANT]
> **Priority Confirmation**: You mentioned Maintenance → Borrowing → Inventory. Should we build them in this exact order, or would you prefer the inventory CRUD first (since borrowing depends on inventory items existing)?

> [!IMPORTANT]
> **Walk-in Borrowing Approval**: For walk-in loans (borrower is physically at GSO), should the HOD approval step be skipped since the borrower is already present? Or is HOD sign-off always required regardless?

> [!NOTE]
> **Supabase Project**: Do you already have a Supabase Cloud project created, or should I include steps to create one? Please share the project URL and anon key when ready (we'll store them in `.env.local`).

> [!NOTE]
> **Flutter Setup**: Do you have Flutter SDK installed and configured on your machine? Which version are you running? (`flutter --version`)
