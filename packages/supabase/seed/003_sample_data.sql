-- ============================================================
-- Seed Data: Sample Users, Rooms, Inventory, and Requests
-- Run AFTER 001_seed.sql and 002_super_admin_account.sql
-- ============================================================

DO $$
DECLARE
    -- Roles
    gso_staff_role_id UUID;
    dept_head_role_id UUID;
    technician_role_id UUID;
    faculty_role_id UUID;
    student_role_id UUID;

    -- Departments
    cict_dept_id UUID;
    mis_dept_id UUID;

    -- Buildings
    cict_bldg_id UUID;
    admin_bldg_id UUID;

    -- Rooms
    cict_lab1_id UUID := uuid_generate_v4();
    cict_lab2_id UUID := uuid_generate_v4();
    admin_conf_id UUID := uuid_generate_v4();

    -- Users
    user_gso_id UUID := uuid_generate_v4();
    user_head_id UUID := uuid_generate_v4();
    user_tech_id UUID := uuid_generate_v4();
    user_faculty_id UUID := uuid_generate_v4();
    user_student_id UUID := uuid_generate_v4();

    -- Categories
    cat_it_inv_id UUID;
    cat_elec_maint_id UUID;

    -- Inventory Items
    item_laptop_id UUID := uuid_generate_v4();
    item_projector_id UUID := uuid_generate_v4();

BEGIN
    -- 1. Fetch existing Role IDs
    SELECT id INTO gso_staff_role_id FROM roles WHERE name = 'gso_staff';
    SELECT id INTO dept_head_role_id FROM roles WHERE name = 'department_head';
    SELECT id INTO technician_role_id FROM roles WHERE name = 'technician';
    SELECT id INTO faculty_role_id FROM roles WHERE name = 'faculty';
    SELECT id INTO student_role_id FROM roles WHERE name = 'student';

    -- 2. Fetch existing Department IDs
    SELECT id INTO cict_dept_id FROM departments WHERE code = 'CICT';
    SELECT id INTO mis_dept_id FROM departments WHERE code = 'MIS';

    -- 3. Fetch existing Building IDs
    SELECT id INTO cict_bldg_id FROM buildings WHERE code = 'CICT';
    SELECT id INTO admin_bldg_id FROM buildings WHERE code = 'ADMIN';

    -- 4. Create Rooms
    INSERT INTO rooms (id, building_id, name, floor, description) VALUES
        (cict_lab1_id, cict_bldg_id, 'Computer Lab 1', 2, 'Main computing laboratory'),
        (cict_lab2_id, cict_bldg_id, 'Computer Lab 2', 2, 'Secondary computing laboratory'),
        (admin_conf_id, admin_bldg_id, 'Conference Room A', 1, 'Main administration conference room')
    ON CONFLICT (id) DO NOTHING;

    -- 5. Seed Users into auth.users (and identities)
    -- Common Password: Password123!
    -- Note: In a real Supabase environment, you'd use the CLI or Admin API, 
    -- but for seed SQL we mimic the super admin pattern.

    -- GSO Staff
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'gso.staff@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
        VALUES (user_gso_id, 'gso.staff@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"GSO Staff Member"}', 'authenticated', 'authenticated');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), user_gso_id, format('{"sub":"%s","email":"%s"}', user_gso_id, 'gso.staff@isufst.edu.ph')::jsonb, 'email', 'gso.staff@isufst.edu.ph', now());
    END IF;

    -- Dept Head
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'dept.head@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
        VALUES (user_head_id, 'dept.head@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Juan Dela Cruz"}', 'authenticated', 'authenticated');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), user_head_id, format('{"sub":"%s","email":"%s"}', user_head_id, 'dept.head@isufst.edu.ph')::jsonb, 'email', 'dept.head@isufst.edu.ph', now());
    END IF;

    -- Technician
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'technician.1@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
        VALUES (user_tech_id, 'technician.1@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Roberto Repair"}', 'authenticated', 'authenticated');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), user_tech_id, format('{"sub":"%s","email":"%s"}', user_tech_id, 'technician.1@isufst.edu.ph')::jsonb, 'email', 'technician.1@isufst.edu.ph', now());
    END IF;

    -- Faculty
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'faculty.1@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
        VALUES (user_faculty_id, 'faculty.1@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Prof. Maria Clara"}', 'authenticated', 'authenticated');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), user_faculty_id, format('{"sub":"%s","email":"%s"}', user_faculty_id, 'faculty.1@isufst.edu.ph')::jsonb, 'email', 'faculty.1@isufst.edu.ph', now());
    END IF;

    -- Student
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'student.1@isufst.edu.ph') THEN
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
        VALUES (user_student_id, 'student.1@isufst.edu.ph', crypt('Password123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Jose Rizal Jr."}', 'authenticated', 'authenticated');
        
        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at)
        VALUES (uuid_generate_v4(), user_student_id, format('{"sub":"%s","email":"%s"}', user_student_id, 'student.1@isufst.edu.ph')::jsonb, 'email', 'student.1@isufst.edu.ph', now());
    END IF;

    -- 6. Seed Profiles
    -- GSO Staff
    INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
    VALUES (user_gso_id, 'GSO Staff Member', 'gso.staff@isufst.edu.ph', mis_dept_id, true, true)
    ON CONFLICT (id) DO NOTHING;

    -- Dept Head
    INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
    VALUES (user_head_id, 'Dr. Juan Dela Cruz', 'dept.head@isufst.edu.ph', cict_dept_id, true, true)
    ON CONFLICT (id) DO NOTHING;

    -- Technician
    INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
    VALUES (user_tech_id, 'Roberto Repair', 'technician.1@isufst.edu.ph', mis_dept_id, true, true)
    ON CONFLICT (id) DO NOTHING;

    -- Faculty
    INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
    VALUES (user_faculty_id, 'Prof. Maria Clara', 'faculty.1@isufst.edu.ph', cict_dept_id, true, true)
    ON CONFLICT (id) DO NOTHING;

    -- Student
    INSERT INTO profiles (id, full_name, email, department_id, is_approved, is_active)
    VALUES (user_student_id, 'Jose Rizal Jr.', 'student.1@isufst.edu.ph', cict_dept_id, true, true)
    ON CONFLICT (id) DO NOTHING;

    -- 7. Assign Roles
    INSERT INTO user_roles (user_id, role_id) VALUES
        (user_gso_id, gso_staff_role_id),
        (user_head_id, dept_head_role_id),
        (user_tech_id, technician_role_id),
        (user_faculty_id, faculty_role_id),
        (user_student_id, student_role_id)
    ON CONFLICT DO NOTHING;

    -- 8. Inventory Items
    SELECT id INTO cat_it_inv_id FROM inventory_categories WHERE name = 'IT / Computing';
    
    INSERT INTO inventory_items (id, item_code, name, description, category_id, building_id, room_id, is_borrowable, quantity, available_quantity)
    VALUES 
        (item_laptop_id, 'LAP-CICT-001', 'Dell Latitude 5420', 'CICT Faculty Laptop', cat_it_inv_id, cict_bldg_id, cict_lab1_id, true, 1, 1),
        (item_projector_id, 'PROJ-CICT-001', 'Epson EB-X06', 'Classroom Projector', cat_it_inv_id, cict_bldg_id, cict_lab1_id, true, 1, 1)
    ON CONFLICT (item_code) DO NOTHING;

    -- 9. Maintenance Requests
    SELECT id INTO cat_elec_maint_id FROM maintenance_categories WHERE name = 'Electrical';

    INSERT INTO maintenance_requests (request_number, requester_id, category_id, building_id, room_id, title, description, priority_level, status)
    VALUES 
        ('MNT-2026-0001', user_faculty_id, cat_elec_maint_id, cict_bldg_id, cict_lab1_id, 'Flickering Lights', 'The lights in Lab 1 are flickering constantly.', 'Medium', 'Submitted'),
        ('MNT-2026-0002', user_student_id, cat_elec_maint_id, cict_bldg_id, cict_lab2_id, 'AC Not Cooling', 'The air conditioning unit in Lab 2 is blowing warm air.', 'High', 'Assigned')
    ON CONFLICT (request_number) DO NOTHING;

    -- 10. Equipment Loans
    INSERT INTO equipment_loans (loan_number, item_id, borrower_id, loan_type, quantity_borrowed, purpose, expected_return_date, status)
    VALUES 
        ('LOAN-2026-0001', item_laptop_id, user_faculty_id, 'reservation', 1, 'Research presentation in Iloilo', now() + interval '3 days', 'Pending_HOD')
    ON CONFLICT (loan_number) DO NOTHING;

    -- 11. Bookings
    INSERT INTO bookings (user_id, room_id, start_time, end_time, status, notes)
    VALUES 
        (user_faculty_id, admin_conf_id, now() + interval '1 day', now() + interval '1 day 2 hours', 'pending', 'Department monthly meeting'),
        (user_student_id, cict_lab1_id, now() + interval '2 days', now() + interval '2 days 4 hours', 'approved', 'Student Council meeting')
    ON CONFLICT DO NOTHING;

END $$;
