-- ============================================================
-- Migration: Fix Schema Gaps
-- Adds: driver + ssc_staff roles, bookings columns,
--       passenger_names column, travel booking auto-number,
--       fixed travel RLS policies, SSC booking approval policy
-- ============================================================

-- ── 1. Add missing roles ──────────────────────────────────────
INSERT INTO public.roles (name, display_name, description, is_system, permissions) VALUES
  ('driver', 'Driver', 'Assigned to drive university vehicles for official travel bookings', true,
    '{"travel": ["read_assigned", "update_status"]}'),
  ('ssc_staff', 'SSC Staff', 'Student Support Center staff — approves student event room bookings', true,
    '{"bookings": ["read", "approve"]}')
ON CONFLICT (name) DO NOTHING;

-- ── 2. Add title + description to bookings ───────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT;

-- ── 3. Add passenger_names to travel_bookings ────────────────
ALTER TABLE public.travel_bookings
  ADD COLUMN IF NOT EXISTS passenger_names TEXT;

-- ── 4. Travel booking auto-number trigger ────────────────────
-- Use a sequence for the numeric part
CREATE SEQUENCE IF NOT EXISTS public.travel_booking_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_travel_booking_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.booking_number IS NULL OR NEW.booking_number = '' THEN
    NEW.booking_number := 'TRV-' || EXTRACT(YEAR FROM NOW())::TEXT
      || '-' || LPAD(nextval('public.travel_booking_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_travel_booking_number ON public.travel_bookings;
CREATE TRIGGER trg_travel_booking_number
  BEFORE INSERT ON public.travel_bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_travel_booking_number();

-- ── 5. Fix Travel Bookings RLS ───────────────────────────────
-- Drop the overly permissive policies
DROP POLICY IF EXISTS "Users can update their own bookings" ON public.travel_bookings;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.travel_bookings;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.vehicles;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON public.vehicles;

-- Requester: view own bookings
DROP POLICY IF EXISTS "Requester views own travel bookings" ON public.travel_bookings;
CREATE POLICY "Requester views own travel bookings"
  ON public.travel_bookings FOR SELECT
  USING (auth.uid() = requester_id);

-- Requester: update own pending bookings (cancel only)
DROP POLICY IF EXISTS "Requester cancels own pending booking" ON public.travel_bookings;
CREATE POLICY "Requester cancels own pending booking"
  ON public.travel_bookings FOR UPDATE
  USING (auth.uid() = requester_id AND status = 'Pending');

-- Driver: view their assigned trips
DROP POLICY IF EXISTS "Driver views assigned trips" ON public.travel_bookings;
CREATE POLICY "Driver views assigned trips"
  ON public.travel_bookings FOR SELECT
  USING (auth.uid() = driver_id);

-- Driver: update status on their assigned trips (Ongoing/Completed)
DROP POLICY IF EXISTS "Driver updates trip status" ON public.travel_bookings;
CREATE POLICY "Driver updates trip status"
  ON public.travel_bookings FOR UPDATE
  USING (auth.uid() = driver_id AND status IN ('Scheduled', 'Ongoing'));

-- GSO/Admin: full management
DROP POLICY IF EXISTS "Staff manages all travel bookings" ON public.travel_bookings;
CREATE POLICY "Staff manages all travel bookings"
  ON public.travel_bookings FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- ── 6. Fix Vehicles RLS (was overly permissive) ──────────────
DROP POLICY IF EXISTS "Staff manages vehicles" ON public.vehicles;
CREATE POLICY "Staff manages vehicles"
  ON public.vehicles FOR ALL
  USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- ── 7. SSC booking approval policy ──────────────────────────
DROP POLICY IF EXISTS "SSC and staff can approve bookings" ON public.bookings;
CREATE POLICY "SSC and staff can approve bookings"
  ON public.bookings FOR UPDATE
  USING (has_any_role(ARRAY['super_admin', 'gso_staff', 'ssc_staff']));
