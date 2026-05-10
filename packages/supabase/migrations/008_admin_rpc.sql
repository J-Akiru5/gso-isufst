-- Migration 008: Admin RPC for user management
-- Bypasses circular RLS when reading all users and their roles
CREATE OR REPLACE FUNCTION get_all_profiles_with_roles()
RETURNS TABLE (
  id uuid,
  full_name text,
  email text,
  phone text,
  department_id uuid,
  employee_student_id text,
  avatar_url text,
  is_approved boolean,
  is_active boolean,
  approved_by uuid,
  approved_at timestamptz,
  rejection_reason text,
  last_seen_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  department_name text,
  user_roles json
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only callable by super_admin or gso_staff
  IF NOT has_any_role(ARRAY['super_admin', 'gso_staff']) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;
  
  RETURN QUERY
    SELECT 
      p.id,
      p.full_name,
      p.email,
      p.phone,
      p.department_id,
      p.employee_student_id,
      p.avatar_url,
      p.is_approved,
      p.is_active,
      p.approved_by,
      p.approved_at,
      p.rejection_reason,
      p.last_seen_at,
      p.created_at,
      p.updated_at,
      d.name AS department_name,
      COALESCE(
        json_agg(
          json_build_object(
            'id', r.id, 
            'name', r.name, 
            'display_name', r.display_name
          )
        ) FILTER (WHERE r.id IS NOT NULL), '[]'::json
      ) AS user_roles
    FROM profiles p
    LEFT JOIN departments d ON p.department_id = d.id
    LEFT JOIN user_roles ur ON ur.user_id = p.id
    LEFT JOIN roles r ON r.id = ur.role_id
    GROUP BY p.id, d.name
    ORDER BY p.created_at DESC;
END;
$$;
