-- ============================================================
-- Seed Data: Travel Booking & Fleet Management
-- ============================================================

DO $$
DECLARE
    faculty_id UUID;
    student_id UUID;
    admin_id UUID;
    driver_1_id UUID;
    driver_2_id UUID;
    vehicle_1_id UUID;
    vehicle_2_id UUID;
    vehicle_3_id UUID;
    booking_id UUID;
BEGIN
    -- Fetch existing users
    SELECT id INTO admin_id FROM profiles WHERE email = 'cictstudentcouncil@isufst.edu.ph';
    SELECT id INTO student_id FROM profiles WHERE email = 'student.1@isufst.edu.ph';
    SELECT id INTO faculty_id FROM profiles WHERE email = 'faculty.1@isufst.edu.ph';

    -- Create or fetch Drivers (We use tech roles/emails as drivers for this seed if none exists, or just create dedicated ones)
    SELECT id INTO driver_1_id FROM profiles WHERE email = 'driver.1@isufst.edu.ph';
    IF driver_1_id IS NULL THEN
        driver_1_id := uuid_generate_v4();
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, instance_id)
        VALUES (driver_1_id, 'driver.1@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dominic Toretto"}', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), driver_1_id, format('{"sub":"%s","email":"%s"}', driver_1_id, 'driver.1@isufst.edu.ph')::jsonb, 'email', 'driver.1@isufst.edu.ph', now());
        
        INSERT INTO profiles (id, full_name, email, is_approved, is_active)
        VALUES (driver_1_id, 'Dominic Toretto', 'driver.1@isufst.edu.ph', true, true) ON CONFLICT (id) DO NOTHING;
    END IF;

    SELECT id INTO driver_2_id FROM profiles WHERE email = 'driver.2@isufst.edu.ph';
    IF driver_2_id IS NULL THEN
        driver_2_id := uuid_generate_v4();
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, instance_id)
        VALUES (driver_2_id, 'driver.2@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Brian OConner"}', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), driver_2_id, format('{"sub":"%s","email":"%s"}', driver_2_id, 'driver.2@isufst.edu.ph')::jsonb, 'email', 'driver.2@isufst.edu.ph', now());
        
        INSERT INTO profiles (id, full_name, email, is_approved, is_active)
        VALUES (driver_2_id, 'Brian OConner', 'driver.2@isufst.edu.ph', true, true) ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Seed Vehicles
    vehicle_1_id := uuid_generate_v4();
    INSERT INTO vehicles (id, plate_number, brand, model, vehicle_type, capacity, status)
    VALUES (vehicle_1_id, 'SGE-123', 'Toyota', 'Hiace', 'Van', 12, 'Available') ON CONFLICT (plate_number) DO NOTHING;

    vehicle_2_id := uuid_generate_v4();
    INSERT INTO vehicles (id, plate_number, brand, model, vehicle_type, capacity, status)
    VALUES (vehicle_2_id, 'WXB-456', 'Mitsubishi', 'Rosa', 'Mini-Bus', 25, 'Available') ON CONFLICT (plate_number) DO NOTHING;

    vehicle_3_id := uuid_generate_v4();
    INSERT INTO vehicles (id, plate_number, brand, model, vehicle_type, capacity, status)
    VALUES (vehicle_3_id, 'XYZ-789', 'Ford', 'Everest', 'SUV', 7, 'Under_Maintenance') ON CONFLICT (plate_number) DO NOTHING;

    -- We need to re-fetch UUIDs in case DO NOTHING bypassed the variable assignment
    SELECT id INTO vehicle_1_id FROM vehicles WHERE plate_number = 'SGE-123';
    SELECT id INTO vehicle_2_id FROM vehicles WHERE plate_number = 'WXB-456';
    SELECT id INTO vehicle_3_id FROM vehicles WHERE plate_number = 'XYZ-789';

    -- Seed Travel Bookings
    
    -- Booking 1: Pending (No vehicle/driver assigned yet)
    booking_id := uuid_generate_v4();
    INSERT INTO travel_bookings (id, booking_number, requester_id, destination, purpose, departure_time, return_time, passenger_count, status)
    VALUES (booking_id, 'TRV-1001', faculty_id, 'Iloilo City Hall', 'Official meeting', now() + interval '2 days', now() + interval '2 days' + interval '4 hours', 4, 'Pending') ON CONFLICT (booking_number) DO NOTHING;

    -- Booking 2: Scheduled (Approved, assigned vehicle and driver)
    booking_id := uuid_generate_v4();
    INSERT INTO travel_bookings (id, booking_number, requester_id, driver_id, vehicle_id, destination, purpose, departure_time, return_time, passenger_count, status, approved_by)
    VALUES (booking_id, 'TRV-1002', student_id, driver_1_id, vehicle_1_id, 'Regional Competition Site', 'Sports meet representation', now() + interval '5 days', now() + interval '7 days', 10, 'Scheduled', admin_id) ON CONFLICT (booking_number) DO NOTHING;

    -- Booking 3: Ongoing (Currently active, vehicle status will be automatically updated by trigger if we set it to ongoing via trigger, but since we are inserting it might not trigger if we just insert. The trigger says ON UPDATE, wait! Let's check trigger definition. It's AFTER UPDATE. So inserting 'Ongoing' won't trigger vehicle update unless we have an AFTER INSERT OR UPDATE. Let's make it Scheduled and then update it to Ongoing).
    booking_id := uuid_generate_v4();
    INSERT INTO travel_bookings (id, booking_number, requester_id, driver_id, vehicle_id, destination, purpose, departure_time, return_time, passenger_count, status, approved_by)
    VALUES (booking_id, 'TRV-1003', faculty_id, driver_2_id, vehicle_2_id, 'Research Facility Extension', 'Field study', now() - interval '1 day', now() + interval '2 days', 20, 'Scheduled', admin_id) ON CONFLICT (booking_number) DO NOTHING;

    -- Now update it to Ongoing to fire the trigger
    UPDATE travel_bookings SET status = 'Ongoing' WHERE booking_number = 'TRV-1003';

    -- Booking 4: Completed
    booking_id := uuid_generate_v4();
    INSERT INTO travel_bookings (id, booking_number, requester_id, driver_id, vehicle_id, destination, purpose, departure_time, return_time, passenger_count, status, approved_by)
    VALUES (booking_id, 'TRV-1004', faculty_id, driver_1_id, vehicle_1_id, 'Local High School', 'Recruitment Drive', now() - interval '10 days', now() - interval '9 days', 5, 'Scheduled', admin_id) ON CONFLICT (booking_number) DO NOTHING;
    
    UPDATE travel_bookings SET status = 'Completed' WHERE booking_number = 'TRV-1004';

END $$;
