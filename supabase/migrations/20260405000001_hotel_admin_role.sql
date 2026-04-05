-- supabase/migrations/20260405000001_hotel_admin_role.sql
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'hotel_admin' AFTER 'super_admin';
