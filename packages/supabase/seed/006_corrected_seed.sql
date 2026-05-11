-- ============================================================
-- Seed 006: Corrected Seed Data
-- Fixes bugs in 004_comprehensive_data.sql and 005_travel_data.sql:
--   1. Assigns driver role to driver users
--   2. Fixes equipment_loans loan_type: 'online' -> 'walk_in'
--   3. Fixes bookings status: uses lowercase enum values
--   4. Adds passenger_names to existing travel bookings
-- ============================================================

DO $$
DECLARE
    role_driver_id   UUID;
    driver_1_id      UUID;
    driver_2_id      UUID;
    faculty_id       UUID;
    student_id       UUID;
    item_id          UUID;
    room_id          UUID;
    i                INTEGER;
    day_offset       INTERVAL;
BEGIN

    -- ── 1. Assign driver role to existing driver users ────────
    SELECT id INTO role_driver_id FROM public.roles WHERE name = 'driver';

    SELECT id INTO driver_1_id FROM public.profiles WHERE email = 'driver.1@isufst.edu.ph';
    SELECT id INTO driver_2_id FROM public.profiles WHERE email = 'driver.2@isufst.edu.ph';

    IF driver_1_id IS NOT NULL AND role_driver_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (driver_1_id, role_driver_id)
        ON CONFLICT (user_id, role_id) DO NOTHING;
    END IF;

    IF driver_2_id IS NOT NULL AND role_driver_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (driver_2_id, role_driver_id)
        ON CONFLICT (user_id, role_id) DO NOTHING;
    END IF;

    -- ── 2. Resolve user IDs with fallbacks ───────────────────
    SELECT id INTO faculty_id FROM public.profiles
    WHERE email = 'faculty.chm.1@isufst.edu.ph';

    IF faculty_id IS NULL THEN
        SELECT id INTO faculty_id FROM public.profiles
        WHERE email LIKE 'faculty%' AND is_active = true
        LIMIT 1;
    END IF;

    SELECT id INTO student_id FROM public.profiles
    WHERE email = 'student.test.1@isufst.edu.ph';

    IF student_id IS NULL THEN
        SELECT id INTO student_id FROM public.profiles
        WHERE email LIKE 'student%' AND is_active = true
        LIMIT 1;
    END IF;

    -- ── 3. Fix equipment loans (loan_type must be walk_in/reservation) ──
    IF student_id IS NOT NULL THEN
        FOR i IN 1..5 LOOP
            SELECT id INTO item_id
            FROM public.inventory_items
            WHERE is_borrowable = true
            LIMIT 1 OFFSET ((i - 1) % 5);

            IF item_id IS NOT NULL THEN
                INSERT INTO public.equipment_loans (
                    loan_number, item_id, borrower_id,
                    loan_type, quantity_borrowed, purpose,
                    expected_return_date, status
                )
                VALUES (
                    'LOAN-FIX-00' || i,
                    item_id,
                    student_id,
                    'walk_in',
                    1,
                    'Academic project use',
                    NOW() + INTERVAL '7 days',
                    'Pending_HOD'
                )
                ON CONFLICT (loan_number) DO NOTHING;
            END IF;
        END LOOP;
    END IF;

    -- ── 4. Fix bookings (use correct lowercase enum status) ───
    IF faculty_id IS NOT NULL THEN
        -- Get a valid room
        SELECT id INTO room_id FROM public.rooms LIMIT 1;

        IF room_id IS NOT NULL THEN
            FOR i IN 1..3 LOOP
                day_offset := (i || ' days')::INTERVAL;
                INSERT INTO public.bookings (
                    room_id, user_id,
                    title, description,
                    start_time, end_time,
                    status
                )
                VALUES (
                    room_id,
                    faculty_id,
                    'Department Meeting ' || i,
                    'Regular departmental coordination meeting.',
                    NOW() + day_offset,
                    NOW() + day_offset + INTERVAL '2 hours',
                    'approved'
                )
                ON CONFLICT DO NOTHING;
            END LOOP;
        END IF;
    END IF;

    -- ── 5. Add passenger_names to existing travel bookings ────
    UPDATE public.travel_bookings
    SET passenger_names = 'Passenger 1, Passenger 2, Passenger 3'
    WHERE passenger_names IS NULL;

END $$;

-- ── Verification queries ──────────────────────────────────────
SELECT 'driver role assignments' AS check_name,
       COUNT(*) AS count
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE r.name = 'driver';

SELECT 'fixed loans' AS check_name, COUNT(*) AS count
FROM public.equipment_loans
WHERE loan_number LIKE 'LOAN-FIX-%';

SELECT 'travel bookings with passenger_names' AS check_name,
       COUNT(*) AS count
FROM public.travel_bookings
WHERE passenger_names IS NOT NULL;
