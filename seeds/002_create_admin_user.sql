-- Seed script: Create admin user
-- Description: Sets the first admin user for the platform
-- Usage: Replace 'YOUR_ADMIN_USER_ID' with actual user ID after registration

-- INSTRUCTIONS:
-- 1. First, register a user account through the application
-- 2. Get the user ID from the profiles table
-- 3. Replace 'YOUR_ADMIN_USER_ID' below with the actual UUID
-- 4. Run this script to grant admin privileges

-- Example: Update specific user to ADMIN role
-- UPDATE profiles
-- SET role = 'ADMIN'
-- WHERE id = 'YOUR_ADMIN_USER_ID';

-- Alternative: Set admin by email (safer for automation)
-- UPDATE profiles
-- SET role = 'ADMIN'
-- WHERE id IN (
--   SELECT id FROM auth.users WHERE email = 'admin@partnersllc.com'
-- );

-- Query to check current roles
-- SELECT 
--   p.id,
--   au.email,
--   p.full_name,
--   p.role
-- FROM profiles p
-- JOIN auth.users au ON au.id = p.id
-- ORDER BY p.role DESC, au.email;
