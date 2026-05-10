-- ============================================================
-- Seed Data: Comprehensive Population (Part 1: Users & Places)
-- ============================================================

DO $$
DECLARE
    -- Dept IDs
    dept_chm_id UUID;
    dept_coed_id UUID;
    dept_coag_id UUID;
    dept_mis_id UUID;
    
    -- Building IDs
    bldg_chm_id UUID;
    bldg_coed_id UUID;
    bldg_coag_id UUID;
    
    -- Role IDs
    role_tech_id UUID;
    role_faculty_id UUID;
    role_student_id UUID;
    
    -- Temp IDs for users
    new_user_id UUID;
BEGIN
    -- Fetch existing IDs
    SELECT id INTO dept_chm_id FROM departments WHERE code = 'CHM';
    SELECT id INTO dept_coed_id FROM departments WHERE code = 'CoED';
    SELECT id INTO dept_coag_id FROM departments WHERE code = 'CoAg';
    SELECT id INTO dept_mis_id FROM departments WHERE code = 'MIS';

    SELECT id INTO bldg_chm_id FROM buildings WHERE code = 'CHM';
    SELECT id INTO bldg_coed_id FROM buildings WHERE code = 'CoED';
    SELECT id INTO bldg_coag_id FROM buildings WHERE code = 'CoAg';

    SELECT id INTO role_tech_id FROM roles WHERE name = 'technician';
    SELECT id INTO role_faculty_id FROM roles WHERE name = 'faculty';
    SELECT id INTO role_student_id FROM roles WHERE name = 'student';

    -- 1. Seed More Rooms
    INSERT INTO rooms (building_id, name, floor, description) VALUES
        (bldg_chm_id, 'Kitchen Lab 1', 1, 'Main cooking laboratory'),
        (bldg_chm_id, 'Dining Hall', 1, 'Practice dining area'),
        (bldg_coed_id, 'Room 101', 1, 'General classroom'),
        (bldg_coed_id, 'Room 102', 1, 'General classroom'),
        (bldg_coag_id, 'Greenhouse 1', 0, 'Plant research facility'),
        (bldg_coag_id, 'Soil Lab', 1, 'Soil analysis laboratory')
    ON CONFLICT DO NOTHING;

    -- 2. Seed More Technicians
    -- Technician: Plumbing
    new_user_id := uuid_generate_v4();
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'tech.plumbing@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, instance_id)
        VALUES (new_user_id, 'tech.plumbing@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Mario Plumber"}', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), new_user_id, format('{"sub":"%s","email":"%s"}', new_user_id, 'tech.plumbing@isufst.edu.ph')::jsonb, 'email', 'tech.plumbing@isufst.edu.ph', now());
        INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
        VALUES (new_user_id, 'Mario Plumber', 'tech.plumbing@isufst.edu.ph', dept_mis_id, true, true)
        ON CONFLICT (id) DO NOTHING;
        INSERT INTO user_roles (user_id, role_id) VALUES (new_user_id, role_tech_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Technician: Electrical
    new_user_id := uuid_generate_v4();
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'tech.elec@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, instance_id)
        VALUES (new_user_id, 'tech.elec@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Nikola Tesla Jr."}', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), new_user_id, format('{"sub":"%s","email":"%s"}', new_user_id, 'tech.elec@isufst.edu.ph')::jsonb, 'email', 'tech.elec@isufst.edu.ph', now());
        INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
        VALUES (new_user_id, 'Nikola Tesla Jr.', 'tech.elec@isufst.edu.ph', dept_mis_id, true, true)
        ON CONFLICT (id) DO NOTHING;
        INSERT INTO user_roles (user_id, role_id) VALUES (new_user_id, role_tech_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- 3. Seed Faculty across departments
    FOR i IN 1..3 LOOP
        new_user_id := uuid_generate_v4();
        IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = format('faculty.chm.%s@isufst.edu.ph', i)) THEN
            INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, instance_id)
            VALUES (new_user_id, format('faculty.chm.%s@isufst.edu.ph', i), crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', format('{"full_name":"CHM Professor %s"}', i)::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
            INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
            VALUES (uuid_generate_v4(), new_user_id, format('{"sub":"%s","email":"%s"}', new_user_id, format('faculty.chm.%s@isufst.edu.ph', i))::jsonb, 'email', format('faculty.chm.%s@isufst.edu.ph', i), now());
            INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
            VALUES (new_user_id, format('CHM Professor %s', i), format('faculty.chm.%s@isufst.edu.ph', i), dept_chm_id, true, true)
            ON CONFLICT (id) DO NOTHING;
            INSERT INTO user_roles (user_id, role_id) VALUES (new_user_id, role_faculty_id)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;

    -- 4. Seed Students
    FOR i IN 1..10 LOOP
        new_user_id := uuid_generate_v4();
        IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = format('student.test.%s@isufst.edu.ph', i)) THEN
            INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, instance_id)
            VALUES (new_user_id, format('student.test.%s@isufst.edu.ph', i), crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', format('{"full_name":"Test Student %s"}', i)::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
            INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
            VALUES (uuid_generate_v4(), new_user_id, format('{"sub":"%s","email":"%s"}', new_user_id, format('student.test.%s@isufst.edu.ph', i))::jsonb, 'email', format('student.test.%s@isufst.edu.ph', i), now());
            INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
            VALUES (new_user_id, format('Test Student %s', i), format('student.test.%s@isufst.edu.ph', i), dept_coed_id, true, true)
            ON CONFLICT (id) DO NOTHING;
            INSERT INTO user_roles (user_id, role_id) VALUES (new_user_id, role_student_id)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;

END $$;

-- ── PART 2: Inventory & Audit Logs ───────────────────────────
DO $$
DECLARE
    cat_av_id UUID;
    cat_lab_id UUID;
    cat_office_id UUID;
    cat_furn_id UUID;
    cat_it_id UUID;
    
    bldg_cict_id UUID;
    room_lab1_id UUID;
    
    admin_id UUID;
    item_id UUID;
BEGIN
    -- Fetch IDs
    SELECT id INTO cat_av_id FROM inventory_categories WHERE name = 'Audio-Visual Equipment';
    SELECT id INTO cat_lab_id FROM inventory_categories WHERE name = 'Laboratory Equipment';
    SELECT id INTO cat_office_id FROM inventory_categories WHERE name = 'Office Equipment';
    SELECT id INTO cat_furn_id FROM inventory_categories WHERE name = 'Furniture';
    SELECT id INTO cat_it_id FROM inventory_categories WHERE name = 'IT / Computing';

    SELECT id INTO bldg_cict_id FROM buildings WHERE code = 'CICT';
    SELECT id INTO room_lab1_id FROM rooms WHERE name = 'Computer Lab 1' AND building_id = bldg_cict_id;
    
    SELECT id INTO admin_id FROM profiles WHERE email = 'cictstudentcouncil@isufst.edu.ph';

    -- 1. Seed Many IT Items
    FOR i IN 1..10 LOOP
        item_id := uuid_generate_v4();
        INSERT INTO inventory_items (id, item_code, name, description, category_id, building_id, room_id, is_borrowable, quantity, available_quantity, condition, created_by)
        VALUES (
            item_id, 
            format('IT-LAP-%s', 100 + i), 
            format('Laptop Model %s', i), 
            'Faculty/Staff issued laptop', 
            cat_it_id, 
            bldg_cict_id, 
            room_lab1_id, 
            true, 1, 1, 'New', admin_id
        ) ON CONFLICT (item_code) DO NOTHING;
        
        -- Audit Log
        INSERT INTO inventory_audit_log (item_id, action, new_values, performed_by, notes)
        VALUES (item_id, 'created', format('{"name": "Laptop Model %s", "code": "IT-LAP-%s"}', i, 100 + i)::jsonb, admin_id, 'Initial seed');
    END LOOP;

    -- 2. Seed AV Equipment
    FOR i IN 1..5 LOOP
        item_id := uuid_generate_v4();
        INSERT INTO inventory_items (id, item_code, name, description, category_id, building_id, is_borrowable, quantity, available_quantity, condition, created_by)
        VALUES (
            item_id, 
            format('AV-PROJ-%s', 200 + i), 
            format('Projector %s', i), 
            'Portable classroom projector', 
            cat_av_id, 
            bldg_cict_id, 
            true, 1, 1, 'Good', admin_id
        ) ON CONFLICT (item_code) DO NOTHING;
    END LOOP;

    -- 3. Seed Lab Equipment
    FOR i IN 1..10 LOOP
        item_id := uuid_generate_v4();
        INSERT INTO inventory_items (id, item_code, name, description, category_id, building_id, is_borrowable, quantity, available_quantity, condition, created_by)
        VALUES (
            item_id, 
            format('LAB-MIC-%s', 300 + i), 
            format('Microscope Type %s', i), 
            'Standard biology microscope', 
            cat_lab_id, 
            bldg_cict_id, 
            false, 1, 1, 'Good', admin_id
        ) ON CONFLICT (item_code) DO NOTHING;
    END LOOP;

    -- 4. Seed Furniture
    FOR i IN 1..20 LOOP
        item_id := uuid_generate_v4();
        INSERT INTO inventory_items (id, item_code, name, description, category_id, building_id, is_borrowable, quantity, available_quantity, condition, created_by)
        VALUES (
            item_id, 
            format('FURN-CHR-%s', 400 + i), 
            format('Ergonomic Chair %s', i), 
            'Standard office chair', 
            cat_furn_id, 
            bldg_cict_id, 
            false, 1, 1, 'New', admin_id
        ) ON CONFLICT (item_code) DO NOTHING;
    END LOOP;

END $$;

-- ── PART 3: Maintenance Requests & Timeline ───────────────────
DO $$
DECLARE
    cat_elec_id UUID;
    cat_plumb_id UUID;
    cat_ac_id UUID;
    
    bldg_cict_id UUID;
    room_lab1_id UUID;
    
    faculty_id UUID;
    tech_plumb_id UUID;
    tech_elec_id UUID;
    admin_id UUID;
    
    req_id UUID;
BEGIN
    -- Fetch IDs
    SELECT id INTO cat_elec_id FROM maintenance_categories WHERE name = 'Electrical';
    SELECT id INTO cat_plumb_id FROM maintenance_categories WHERE name = 'Plumbing';
    SELECT id INTO cat_ac_id FROM maintenance_categories WHERE name = 'Air Conditioning / HVAC';

    SELECT id INTO bldg_cict_id FROM buildings WHERE code = 'CICT';
    SELECT id INTO room_lab1_id FROM rooms WHERE name = 'Computer Lab 1' AND building_id = bldg_cict_id;
    
    SELECT id INTO faculty_id FROM profiles WHERE email = 'faculty.1@isufst.edu.ph';
    SELECT id INTO tech_plumb_id FROM profiles WHERE email = 'tech.plumbing@isufst.edu.ph';
    SELECT id INTO tech_elec_id FROM profiles WHERE email = 'tech.elec@isufst.edu.ph';
    SELECT id INTO admin_id FROM profiles WHERE email = 'cictstudentcouncil@isufst.edu.ph';

    -- 1. Request: Completed Workflow
    req_id := uuid_generate_v4();
    INSERT INTO maintenance_requests (id, request_number, requester_id, category_id, building_id, room_id, title, description, priority_level, status, assigned_to, assigned_at, completed_at)
    VALUES (
        req_id, 'MNT-C-1001', faculty_id, cat_elec_id, bldg_cict_id, room_lab1_id, 
        'Broken Light Switch', 'Switch near the entrance is broken.', 'Medium', 'Completed', 
        tech_elec_id, now() - interval '2 days', now() - interval '1 day'
    ) ON CONFLICT DO NOTHING;
    
    INSERT INTO maintenance_timeline (request_id, status, title, description, performed_by) VALUES
        (req_id, 'Submitted', 'Request Created', 'Initial submission by faculty.', faculty_id),
        (req_id, 'Assigned', 'Assigned to Technician', 'Assigned to Nikola Tesla Jr.', admin_id),
        (req_id, 'In_Progress', 'Work Started', 'Technician is on site.', tech_elec_id),
        (req_id, 'Completed', 'Work Finished', 'Switch replaced and tested.', tech_elec_id);

    -- 2. Request: In Progress
    req_id := uuid_generate_v4();
    INSERT INTO maintenance_requests (id, request_number, requester_id, category_id, building_id, room_id, title, description, priority_level, status, assigned_to, assigned_at)
    VALUES (
        req_id, 'MNT-P-2001', faculty_id, cat_plumb_id, bldg_cict_id, room_lab1_id, 
        'Leaky Faucet', 'Faucet in the pantry area is leaking.', 'Low', 'In_Progress', 
        tech_plumb_id, now() - interval '5 hours'
    ) ON CONFLICT DO NOTHING;

    INSERT INTO maintenance_timeline (request_id, status, title, description, performed_by) VALUES
        (req_id, 'Submitted', 'Request Created', 'Initial submission.', faculty_id),
        (req_id, 'Assigned', 'Assigned to Technician', 'Assigned to Mario Plumber.', admin_id),
        (req_id, 'In_Progress', 'Started Repair', 'Disassembling the faucet.', tech_plumb_id);

    -- 3. Request: Urgent Pending
    FOR i IN 1..5 LOOP
        INSERT INTO maintenance_requests (request_number, requester_id, category_id, building_id, title, description, priority_level, status)
        VALUES (
            format('MNT-U-%s', 300 + i), faculty_id, cat_ac_id, bldg_cict_id, 
            format('AC Issue %s', i), 'Unit is making loud noise.', 'High', 'Submitted'
        ) ON CONFLICT DO NOTHING;
    END LOOP;

END $$;

-- ── PART 4: Equipment Loans & Notifications ──────────────────
DO $$
DECLARE
    item_id UUID;
    student_id UUID;
    faculty_id UUID;
    admin_id UUID;
    loan_id UUID;
BEGIN
    SELECT id INTO admin_id FROM profiles WHERE email = 'cictstudentcouncil@isufst.edu.ph';
    SELECT id INTO student_id FROM profiles WHERE email = 'student.1@isufst.edu.ph';
    SELECT id INTO faculty_id FROM profiles WHERE email = 'faculty.1@isufst.edu.ph';
    
    -- 1. Overdue Loan
    SELECT id INTO item_id FROM inventory_items WHERE item_code = 'IT-LAP-101';
    IF item_id IS NOT NULL THEN
        loan_id := uuid_generate_v4();
        INSERT INTO equipment_loans (id, loan_number, item_id, borrower_id, loan_type, quantity_borrowed, purpose, expected_return_date, actual_pickup_date, status)
        VALUES (
            loan_id, 'LOAN-O-4001', item_id, student_id, 'walk_in', 1, 'Group project', 
            now() - interval '2 days', now() - interval '5 days', 'Overdue'
        ) ON CONFLICT DO NOTHING;
        
        INSERT INTO loan_timeline (loan_id, status, title, description, performed_by) VALUES
            (loan_id, 'Released', 'Item Released', 'Laptop issued to student.', admin_id);
            
        -- Notification for overdue
        INSERT INTO notifications (user_id, title, body, type, reference_type, reference_id)
        VALUES (student_id, 'Equipment Overdue', 'Please return the Laptop Model 1 as soon as possible.', 'loan', 'equipment_loan', loan_id);
    END IF;

    -- 2. Bulk Notifications for System Updates
    FOR i IN 1..10 LOOP
        INSERT INTO notifications (user_id, title, body, type)
        VALUES (
            (SELECT id FROM profiles OFFSET (i % 5) LIMIT 1),
            format('System Update %s', i),
            'The GSO system has been updated with new features.',
            'system'
        );
    END LOOP;

    -- 3. Loan Approvals history
    -- (Handled by the workflow above mostly)

END $$;

-- ── PART 5: Boosting Counts (Targets: 50+ Inv, 20+ Maint, 15+ Loans, 20+ Notifs) ──
DO $$
DECLARE
    cat_it_id UUID;
    cat_ac_id UUID;
    bldg_cict_id UUID;
    admin_id UUID;
    student_id UUID;
    faculty_id UUID;
    item_id UUID;
BEGIN
    SELECT id INTO cat_it_id FROM inventory_categories WHERE name = 'IT / Computing';
    SELECT id INTO cat_ac_id FROM maintenance_categories WHERE name = 'Air Conditioning / HVAC';
    SELECT id INTO bldg_cict_id FROM buildings WHERE code = 'CICT';
    SELECT id INTO admin_id FROM profiles WHERE email = 'cictstudentcouncil@isufst.edu.ph';
    SELECT id INTO student_id FROM profiles WHERE email = 'student.1@isufst.edu.ph';
    SELECT id INTO faculty_id FROM profiles WHERE email = 'faculty.1@isufst.edu.ph';

    -- 1. Extra Inventory (Need ~5 more)
    FOR i IN 1..10 LOOP
        INSERT INTO inventory_items (item_code, name, description, category_id, building_id, is_borrowable, quantity, available_quantity, condition, created_by)
        VALUES (
            format('EXTRA-ITEM-%s', i), 
            format('Extra Item %s', i), 
            'Generic extra item for testing', 
            cat_it_id, bldg_cict_id, true, 5, 5, 'New', admin_id
        ) ON CONFLICT DO NOTHING;
    END LOOP;

    -- 2. Extra Maintenance (Need ~11 more)
    FOR i IN 1..15 LOOP
        INSERT INTO maintenance_requests (request_number, requester_id, category_id, building_id, title, description, priority_level, status)
        VALUES (
            format('MNT-EXTRA-%s', i), faculty_id, cat_ac_id, bldg_cict_id, 
            format('Extra Maintenance %s', i), 'Routine check requested.', 
            CASE WHEN i % 3 = 0 THEN 'High'::priority_level ELSE 'Low'::priority_level END,
            'Submitted'
        ) ON CONFLICT DO NOTHING;
    END LOOP;

    -- 3. Extra Loans (Need ~13 more)
    FOR i IN 1..15 LOOP
        SELECT id INTO item_id FROM inventory_items WHERE is_borrowable = true LIMIT 1 OFFSET (i % 5);
        INSERT INTO equipment_loans (loan_number, item_id, borrower_id, loan_type, quantity_borrowed, purpose, status)
        VALUES (
            format('LOAN-EXTRA-%s', i), item_id, student_id, 'walk_in', 1, 'Academic use', 'Pending'
        ) ON CONFLICT DO NOTHING;
    END LOOP;

    -- 4. Extra Bookings
    FOR i IN 1..10 LOOP
        INSERT INTO bookings (room_id, user_id, title, description, start_time, end_time, status)
        VALUES (
            (SELECT id FROM rooms LIMIT 1 OFFSET (i % 3)),
            faculty_id,
            format('Meeting %s', i),
            'Departmental meeting',
            now() + (i || ' hours')::interval,
            now() + ((i + 2) || ' hours')::interval,
            'Approved'
        ) ON CONFLICT DO NOTHING;
    END LOOP;

    -- 5. Extra Notifications
    FOR i IN 1..10 LOOP
        INSERT INTO notifications (user_id, title, body, type)
        VALUES (
            student_id,
            format('Alert %s', i),
            'Check your pending loans.',
            'loan'
        );
    END LOOP;

END $$;
