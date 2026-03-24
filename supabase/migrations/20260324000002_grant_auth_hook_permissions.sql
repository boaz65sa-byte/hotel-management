-- supabase/migrations/20260324000002_grant_auth_hook_permissions.sql
-- Auth Hook runs as supabase_auth_admin — needs SELECT on public.users

GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT SELECT ON public.users TO supabase_auth_admin;
